import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — VP Academy",
  description: "Privacy policy for VP Academy.",
};

export default function Privacy() {
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
          Privacy Policy
        </h1>
        <p className="mb-12 text-sm text-text-tertiary">Last updated: February 25, 2026</p>

        <div className="space-y-8 text-sm leading-relaxed text-text-secondary">
          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">1. Information We Collect</h2>
            <p>VP Academy collects minimal data to provide and improve the App:</p>
            <ul className="mt-2 list-disc space-y-1 pl-6">
              <li>
                <strong className="text-text-primary">Account information:</strong> If you create an account, we
                collect your email address and display name.
              </li>
              <li>
                <strong className="text-text-primary">Usage data:</strong> We collect anonymized data about how you
                interact with the App, such as lessons completed and features used, to improve the experience.
              </li>
              <li>
                <strong className="text-text-primary">Device information:</strong> Basic device information (device
                type, OS version) for compatibility and debugging purposes.
              </li>
            </ul>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">2. How We Use Your Information</h2>
            <p>We use the information we collect to:</p>
            <ul className="mt-2 list-disc space-y-1 pl-6">
              <li>Provide, maintain, and improve the App</li>
              <li>Sync your progress across devices</li>
              <li>Send important updates about the App (with your consent)</li>
              <li>Analyze usage patterns to improve features and content</li>
            </ul>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">3. Information Sharing</h2>
            <p>
              We do not sell, trade, or rent your personal information to third parties. We may
              share anonymized, aggregated data that cannot be used to identify you for analytics
              and improvement purposes.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">4. Data Security</h2>
            <p>
              We implement industry-standard security measures to protect your data. However, no
              method of electronic storage or transmission is 100% secure, and we cannot guarantee
              absolute security.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">5. Data Retention</h2>
            <p>
              We retain your data for as long as your account is active or as needed to provide
              you with the App&apos;s services. You may request deletion of your data at any time by
              contacting us.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">6. Children&apos;s Privacy</h2>
            <p>
              VP Academy is not intended for children under 17. We do not knowingly collect
              personal information from children. If we learn that we have collected information
              from a child under 17, we will promptly delete it.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">7. Changes to This Policy</h2>
            <p>
              We may update this Privacy Policy from time to time. We will notify you of any
              material changes by posting the new policy within the App or on our website. Your
              continued use of the App after changes are posted constitutes acceptance of the
              revised policy.
            </p>
          </section>

          <section>
            <h2 className="mb-3 text-lg font-semibold text-text-primary">8. Contact</h2>
            <p>
              If you have any questions about this Privacy Policy, please contact us at{" "}
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
