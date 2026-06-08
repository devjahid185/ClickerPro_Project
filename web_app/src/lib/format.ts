// Shared formatting helpers for the ClickerPro web app.
//
// Consolidates the currency formatter that was copy-pasted (identically)
// across ~17 pages. Behavior is byte-for-byte the same as the inline
// version: `'৳' + Number(n).toLocaleString('en-BD')`.
//
// NOTE: date formatting is intentionally NOT centralized here yet — pages
// use different month styles ('short' vs 'long'), so a single helper would
// change some UIs. Leave those as-is until a deliberate format decision.

/** Format a number as Bangladeshi Taka, e.g. tk(1500) -> "৳1,500". */
export const tk = (n: number): string => '৳' + Number(n).toLocaleString('en-BD');
