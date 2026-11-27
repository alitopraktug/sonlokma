BEGIN;

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('CUSTOMER', 'BUSINESS', 'ADMIN');

-- CreateEnum
CREATE TYPE "BusinessStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "Category" AS ENUM ('BAKERY', 'CAFE', 'RESTAURANT', 'MARKET');

-- CreateEnum
CREATE TYPE "PackageStatus" AS ENUM ('ACTIVE', 'SOLD_OUT', 'EXPIRED');

-- CreateEnum
CREATE TYPE "OrderType" AS ENUM ('PURCHASE', 'DONATION', 'CLAIM');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING_PAYMENT', 'PAID', 'PICKED_UP', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "SuspendedStatus" AS ENUM ('AVAILABLE', 'CLAIMED');

-- CreateEnum
CREATE TYPE "Allergen" AS ENUM ('GLUTEN', 'CRUSTACEANS', 'EGGS', 'FISH', 'PEANUTS', 'SOY', 'MILK', 'NUTS', 'CELERY', 'MUSTARD', 'SESAME', 'SULPHITES', 'LUPIN', 'MOLLUSCS');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "phone" VARCHAR(16),
    "phoneVerified" BOOLEAN NOT NULL DEFAULT false,
    "name" TEXT,
    "email" TEXT,
    "role" "Role" NOT NULL DEFAULT 'CUSTOMER',
    "kvkkAcceptedAt" TIMESTAMPTZ(3),
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Neighborhood" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Neighborhood_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Business" (
    "id" UUID NOT NULL,
    "ownerId" UUID NOT NULL,
    "neighborhoodId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "category" "Category" NOT NULL,
    "address" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "status" "BusinessStatus" NOT NULL DEFAULT 'PENDING',

    CONSTRAINT "Business_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Package" (
    "id" UUID NOT NULL,
    "businessId" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "category" "Category" NOT NULL,
    "contentHints" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "allergens" "Allergen"[] DEFAULT ARRAY[]::"Allergen"[],
    "originalPrice" INTEGER NOT NULL,
    "price" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "available" INTEGER NOT NULL,
    "pickupStart" TIMESTAMPTZ(3) NOT NULL,
    "pickupEnd" TIMESTAMPTZ(3) NOT NULL,
    "photoUrl" TEXT,
    "photoIsRepresentative" BOOLEAN NOT NULL DEFAULT true,
    "suspendable" BOOLEAN NOT NULL DEFAULT false,
    "status" "PackageStatus" NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT "Package_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Order" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "packageId" UUID NOT NULL,
    "type" "OrderType" NOT NULL,
    "quantity" INTEGER NOT NULL,
    "totalPrice" INTEGER NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "idempotencyKey" UUID NOT NULL,
    "reservationExpiresAt" TIMESTAMPTZ(3) NOT NULL,
    "pickedUpAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SuspendedMeal" (
    "id" UUID NOT NULL,
    "businessId" UUID NOT NULL,
    "donationOrderId" UUID NOT NULL,
    "claimOrderId" UUID,
    "status" "SuspendedStatus" NOT NULL DEFAULT 'AVAILABLE',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "claimedAt" TIMESTAMPTZ(3),

    CONSTRAINT "SuspendedMeal_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Neighborhood_city_district_name_key" ON "Neighborhood"("city", "district", "name");

-- CreateIndex
CREATE INDEX "Business_ownerId_idx" ON "Business"("ownerId");

-- CreateIndex
CREATE INDEX "Business_neighborhoodId_status_idx" ON "Business"("neighborhoodId", "status");

-- CreateIndex
CREATE INDEX "Package_businessId_status_pickupEnd_idx" ON "Package"("businessId", "status", "pickupEnd");

-- CreateIndex
CREATE INDEX "Order_userId_createdAt_idx" ON "Order"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Order_packageId_idx" ON "Order"("packageId");

-- CreateIndex
CREATE INDEX "Order_status_reservationExpiresAt_idx" ON "Order"("status", "reservationExpiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "Order_userId_idempotencyKey_key" ON "Order"("userId", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "SuspendedMeal_claimOrderId_key" ON "SuspendedMeal"("claimOrderId");

-- CreateIndex
CREATE INDEX "SuspendedMeal_businessId_status_createdAt_idx" ON "SuspendedMeal"("businessId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "SuspendedMeal_donationOrderId_idx" ON "SuspendedMeal"("donationOrderId");

-- AddForeignKey
ALTER TABLE "Business" ADD CONSTRAINT "Business_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Business" ADD CONSTRAINT "Business_neighborhoodId_fkey" FOREIGN KEY ("neighborhoodId") REFERENCES "Neighborhood"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Package" ADD CONSTRAINT "Package_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "Business"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "Package"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspendedMeal" ADD CONSTRAINT "SuspendedMeal_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "Business"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspendedMeal" ADD CONSTRAINT "SuspendedMeal_donationOrderId_fkey" FOREIGN KEY ("donationOrderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspendedMeal" ADD CONSTRAINT "SuspendedMeal_claimOrderId_fkey" FOREIGN KEY ("claimOrderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Invariants that Prisma's schema language cannot express.
ALTER TABLE "User" ADD CONSTRAINT "User_phone_check" CHECK (
  ("phone" IS NOT NULL AND "phone" ~ '^[+][1-9][0-9]{7,14}$')
  OR ("phone" IS NULL AND "deletedAt" IS NOT NULL AND NOT "phoneVerified")
);
ALTER TABLE "Neighborhood" ADD CONSTRAINT "Neighborhood_coordinates_check"
  CHECK ("lat" BETWEEN -90 AND 90 AND "lng" BETWEEN -180 AND 180);
ALTER TABLE "Business" ADD CONSTRAINT "Business_coordinates_check"
  CHECK ("lat" BETWEEN -90 AND 90 AND "lng" BETWEEN -180 AND 180);
ALTER TABLE "Package"
  ADD CONSTRAINT "Package_stock_check" CHECK ("quantity" > 0 AND "available" BETWEEN 0 AND "quantity"),
  ADD CONSTRAINT "Package_price_check" CHECK ("price" >= 0 AND "originalPrice" >= "price"),
  ADD CONSTRAINT "Package_window_check" CHECK ("pickupEnd" > "pickupStart");
ALTER TABLE "Order"
  ADD CONSTRAINT "Order_amount_check" CHECK ("quantity" > 0 AND "totalPrice" >= 0),
  ADD CONSTRAINT "Order_donation_check" CHECK ("type" <> 'DONATION' OR "quantity" <= 10),
  ADD CONSTRAINT "Order_claim_check" CHECK ("type" <> 'CLAIM' OR ("quantity" = 1 AND "totalPrice" = 0));
CREATE UNIQUE INDEX "Order_one_claim_per_local_day"
  ON "Order" ("userId", (("createdAt" AT TIME ZONE 'Europe/Istanbul')::date))
  WHERE "type" = 'CLAIM';
ALTER TABLE "SuspendedMeal" ADD CONSTRAINT "SuspendedMeal_claim_check" CHECK (
  ("status" = 'AVAILABLE' AND "claimOrderId" IS NULL AND "claimedAt" IS NULL)
  OR ("status" = 'CLAIMED' AND "claimOrderId" IS NOT NULL AND "claimedAt" IS NOT NULL
      AND "claimOrderId" <> "donationOrderId")
);

COMMIT;
