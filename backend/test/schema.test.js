import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { test } from 'node:test';
import { PrismaClient } from '@prisma/client';

// CI supplies a dedicated PostgreSQL database and applies migrations before npm test.
const integration = process.env.NODE_ENV === 'test' && Boolean(process.env.DATABASE_URL);

test('initial migration enforces inventory, idempotency and Istanbul claim days', { skip: !integration }, async () => {
  const db = new PrismaClient();
  const rollback = new Error('rollback test fixtures');
  try {
    await assert.rejects(db.$transaction(async (tx) => {
      const phone = '+90' + BigInt('0x' + randomUUID().replaceAll('-', '').slice(0, 12))
        .toString().padStart(10, '0').slice(-10);
      const user = await tx.user.create({ data: { phone, phoneVerified: true } });
      const area = await tx.neighborhood.create({ data: {
        city: 'Test', district: 'Test', name: randomUUID(), lat: 41, lng: 29
      } });
      const business = await tx.business.create({ data: {
        ownerId: user.id, neighborhoodId: area.id, name: 'Test', category: 'CAFE',
        address: 'Test', lat: 41, lng: 29
      } });
      const pack = await tx.package.create({ data: {
        businessId: business.id, title: 'Test', category: 'CAFE', originalPrice: 2000,
        price: 1000, quantity: 1, available: 1,
        pickupStart: new Date('2026-11-26T20:00:00Z'), pickupEnd: new Date('2026-11-27T22:00:00Z')
      } });
      async function rejectsWrite(write, matches) {
        await tx.$executeRaw`SAVEPOINT invalid_write`;
        await assert.rejects(write(), matches);
        await tx.$executeRaw`ROLLBACK TO SAVEPOINT invalid_write`;
        await tx.$executeRaw`RELEASE SAVEPOINT invalid_write`;
      }
      await rejectsWrite(() => tx.package.update({ where: { id: pack.id }, data: { available: -1 } }), (error) => error.message.includes('Package_stock_check'));
      const claim = {
        userId: user.id, packageId: pack.id, type: 'CLAIM', quantity: 1, totalPrice: 0,
        status: 'PAID', idempotencyKey: randomUUID(), createdAt: new Date('2026-11-26T20:59:59Z'),
        reservationExpiresAt: new Date('2026-11-26T21:09:59Z')
      };
      await tx.order.create({ data: claim });
      await rejectsWrite(() => tx.order.create({ data: { ...claim, type: 'PURCHASE' } }), (error) => error.code === 'P2002');
      await rejectsWrite(() => tx.order.create({ data: { ...claim, idempotencyKey: randomUUID() } }), (error) => error.code === 'P2002');
      await tx.order.create({ data: {
        ...claim, idempotencyKey: randomUUID(), createdAt: new Date('2026-11-26T21:00:00Z')
      } });
      throw rollback;
    }), (error) => error === rollback);
  } finally {
    await db.$disconnect();
  }
});
