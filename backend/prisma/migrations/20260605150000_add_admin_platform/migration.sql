-- AlterTable: User 2FA
ALTER TABLE "User" ADD COLUMN "twoFactorEnabled" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN "totpSecret" TEXT;

-- CreateTable: AppSetting
CREATE TABLE "AppSetting" (
    "key"       TEXT NOT NULL,
    "value"     TEXT,
    "group"     TEXT NOT NULL DEFAULT 'general',
    "isSecret"  BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AppSetting_pkey" PRIMARY KEY ("key")
);

-- CreateTable: Coupon
CREATE TABLE "Coupon" (
    "id"             TEXT NOT NULL,
    "code"           TEXT NOT NULL,
    "description"    TEXT,
    "discountType"   TEXT NOT NULL DEFAULT 'PERCENT',
    "discountValue"  INTEGER NOT NULL DEFAULT 0,
    "maxRedemptions" INTEGER,
    "redeemedCount"  INTEGER NOT NULL DEFAULT 0,
    "expiresAt"      TIMESTAMP(3),
    "active"         BOOLEAN NOT NULL DEFAULT true,
    "createdAt"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Coupon_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Coupon_code_key" ON "Coupon"("code");

-- CreateTable: LoginActivity
CREATE TABLE "LoginActivity" (
    "id"        TEXT NOT NULL,
    "userId"    TEXT,
    "email"     TEXT NOT NULL,
    "ip"        TEXT,
    "userAgent" TEXT,
    "success"   BOOLEAN NOT NULL DEFAULT false,
    "reason"    TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LoginActivity_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "LoginActivity_email_idx" ON "LoginActivity"("email");
CREATE INDEX "LoginActivity_createdAt_idx" ON "LoginActivity"("createdAt");

-- CreateTable: BlockedIp
CREATE TABLE "BlockedIp" (
    "ip"        TEXT NOT NULL,
    "reason"    TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BlockedIp_pkey" PRIMARY KEY ("ip")
);
