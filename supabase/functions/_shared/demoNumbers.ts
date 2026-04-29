// Phone numbers reserved for App Store / Play Store reviewers and internal demos.
// These bypass Twilio SMS and accept the static OTP code DEMO_OTP_CODE.
//
// SECURITY: This is a server-side allowlist. Do NOT mirror in the client.
// The bypass exists so reviewers can test the app without a working SMS service.
// Real users on real numbers continue through the normal Twilio flow.
//
// If reviewer access ever leaks into the wild, rotate this list and ship a patch.

export const DEMO_PHONE_NUMBERS: ReadonlySet<string> = new Set([
  "+15550000001", // US primary reviewer demo (Florida)
  "+15550000002", // US secondary demo (friend account)
  "+15550000003", // US tertiary demo (friend account)
  "+61400000001", // AU Darwin demo
]);

export const DEMO_OTP_CODE = "0001";

export function isDemoPhone(phone: string): boolean {
  return DEMO_PHONE_NUMBERS.has(phone);
}
