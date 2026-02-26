import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms & Conditions — VP Academy",
  description: "Terms and conditions for using VP Academy.",
};

export default function Terms() {
  return (
    <div className="min-h-screen px-6 py-16">
      <article className="mx-auto max-w-3xl">
        <Link
          href="/"
          className="mb-8 inline-flex items-center gap-1 text-sm text-text-secondary transition-colors hover:text-mint"
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
            <path d="M10 12L6 8l4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          Back to Home
        </Link>

        <h1 className="mb-2 text-3xl font-bold text-text-primary md:text-4xl">
          Terms &amp; Conditions
        </h1>
        <p className="mb-12 text-sm text-text-tertiary">Last updated: February 25, 2026</p>

        <div className="space-y-8 text-sm leading-relaxed text-text-secondary">
          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">1. Acceptance of Terms</h2>
            <p>
              By downloading, installing, or using VP Academy (&quot;the App&quot;), you agree to be bound
              by these Terms &amp; Conditions. If you do not agree to these terms, do not use the App.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">2. License</h2>
            <p>
              We grant you a limited, non-exclusive, non-transferable, revocable license to use the
              App for your personal, non-commercial use on any Apple device that you own or control,
              subject to these Terms and the Apple App Store Terms of Service.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">3. User Conduct</h2>
            <p>You agree not to:</p>
            <ul className="mt-2 list-disc space-y-1 pl-6">
              <li>Reverse engineer, decompile, or disassemble the App</li>
              <li>Reproduce, redistribute, or sublicense the App</li>
              <li>Use the App for any unlawful purpose</li>
              <li>Attempt to gain unauthorized access to the App&apos;s systems or networks</li>
            </ul>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">4. Subscriptions &amp; Purchases</h2>
            <p>
              VP Academy may offer premium features through in-app subscriptions. Subscriptions
              are managed through Apple&apos;s App Store and are subject to Apple&apos;s subscription
              terms. You can manage or cancel your subscription at any time through your App Store
              account settings.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">5. Disclaimers</h2>
            <p>
              VP Academy is an educational tool designed to teach video poker strategy. The App
              does not facilitate real-money gambling. Strategy information is provided for
              educational purposes only and does not guarantee winnings at any casino or gambling
              establishment.
            </p>
            <p className="mt-2">
              The App is provided &quot;as is&quot; without warranties of any kind, either express or
              implied, including but not limited to implied warranties of merchantability, fitness
              for a particular purpose, or non-infringement.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">6. Limitation of Liability</h2>
            <p>
              To the maximum extent permitted by law, VP Academy and its developers shall not be
              liable for any indirect, incidental, special, consequential, or punitive damages,
              or any loss of profits or revenues, whether incurred directly or indirectly, arising
              from your use of the App.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">7. Changes to Terms</h2>
            <p>
              We reserve the right to modify these Terms at any time. Changes will be effective
              when posted within the App or on our website. Your continued use of the App after
              changes are posted constitutes acceptance of the revised Terms.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">8. Contact</h2>
            <p>
              If you have any questions about these Terms, please contact us at{" "}
              <a href="mailto:support@videopoker.academy" className="text-mint hover:underline">
                support@videopoker.academy
              </a>.
            </p>
          </section>
        </div>
      </article>
    </div>
  );
}
