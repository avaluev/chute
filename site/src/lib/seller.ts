// WHO IS LEGALLY SELLING. One definition, rendered by /terms, /support and the footer.
//
// Paddle's domain review names an unidentified seller as a rejection cause:
//   "Include the company name or sole proprietor's brand (legal name preferred for sole
//    proprietors) in the Terms & Conditions."
//   — paddle.com/help/start/account-verification/what-is-domain-verification
//
// These are the same registration details already published on studylock.org, the same natural
// person, supplied by the founder 2026-08-18. Never retype them into prose: scripts/check-paddle.mjs
// fails the build if the registered name stops appearing in the rendered /terms page.
//
// DELIBERATELY ABSENT: the taxpayer number (INN). A Kyrgyz personal INN encodes the holder's date
// of birth, so publishing it beside a full legal name and a home address would publish a complete
// identity-theft package. Paddle's domain review does not ask for it — only the KYC form does, and
// that is a private form, not a public page. Do not add it here.

export interface PostalAddress {
  line1: string;
  city: string;
  postalCode: string;
  country: string;
  /** ISO 3166-1 alpha-2, for schema.org and any form wanting a code. */
  countryCode: string;
}

export interface SellerIdentity {
  /** The natural person's full legal name, as registered. */
  legalName: string;
  /** The registered business name — the string Paddle's reviewer looks for in the terms. */
  registeredName: string;
  /** Plain English, for a reader who does not know what "IE" means. */
  entityType: string;
  address: PostalAddress;
  contactEmail: string;
}

export const SELLER: SellerIdentity = Object.freeze({
  legalName: "Valuev Aleksandr Aleksandrovich",
  registeredName: "IE Valuev Aleksandr Aleksandrovich",
  entityType: "an Individual Entrepreneur registered in the Kyrgyz Republic",
  address: Object.freeze({
    line1: "BCHK Street, 18A",
    city: "Bishkek",
    postalCode: "720021",
    country: "Kyrgyz Republic",
    countryCode: "KG",
  }),
  contactEmail: "hello@chutedev.com",
}) as SellerIdentity;

/** Most-specific first. An array, so the caller picks the separator. */
export function sellerAddressLines(s: SellerIdentity = SELLER): string[] {
  return [s.address.line1, s.address.city, s.address.postalCode, s.address.country];
}

export function sellerAddressInline(s: SellerIdentity = SELLER): string {
  return sellerAddressLines(s).join(", ");
}
