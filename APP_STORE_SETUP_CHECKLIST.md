# AI Content Machine Store Setup Checklist

This checklist covers the external steps that still need to be completed outside the codebase for subscriptions and App Store readiness.

## 1. App Store Connect

- Create the app record for the production bundle identifier.
- Create the subscription group:
  - `AI Content Machine Pro`
- Create these auto-renewable subscriptions:
  - `com.abebait.aicontentmachine.pro.monthly`
  - `com.abebait.aicontentmachine.pro.yearly`
- Add localized display names and descriptions for both products.
- Set pricing for monthly and yearly.
- Add screenshots, icon, marketing text, and App Store description.
- Add review notes explaining:
  - Free tier includes limited generations and free templates
  - Pro unlocks Pro templates, unlimited generations, Batch Ideas, Local AI Server mode, and premium export

## 2. Legal and Support URLs

Decide and publish the final URLs for:

- Privacy Policy
- Terms of Service / Subscription Terms
- Support / Contact page

Current in-app paywall links still use generic Apple legal destinations for Terms/Privacy and the Apple subscriptions page for Manage Subscription.

## 3. Banking / Tax / Agreements

- Accept the latest Apple paid applications agreement
- Complete banking information
- Complete tax information
- Ensure the account is allowed to sell subscriptions

## 4. StoreKit Testing in Xcode

- Open the scheme for `AIContentMachine`
- Go to `Edit Scheme`
- Under `Run` and `Test` -> `Options`
- Assign the StoreKit configuration file:
  - `AIContentMachine/AIContentMachine.storekit`

## 5. Product Decisions To Confirm

- Final monthly price
- Final yearly price
- Whether yearly should offer a visible discount message
- Final legal copy for the paywall
- Final support email or support URL

## 6. QA Checklist

- Verify paywall opens from:
  - Pro template taps
  - Batch Ideas selection
  - Local AI Server selection
  - Free generation limit reached
  - Premium copy/export actions
  - Settings upgrade CTA
  - Dashboard upgrade CTA
- Verify restore purchases
- Verify yearly and monthly both purchase successfully in StoreKit testing
- Verify downgrade / cancellation behavior updates entitlement state
- Verify free generation limit resets correctly on a new month boundary
