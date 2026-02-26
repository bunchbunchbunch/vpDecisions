import Image from "next/image";

const APP_STORE_URL = "#"; // TODO: Replace with actual App Store URL

export default function Hero() {
  return (
    <section className="relative overflow-hidden px-6 py-24 md:py-36">
      {/* Ambient glow */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(110,237,198,0.08)_0%,_transparent_70%)]" />

      <div className="relative mx-auto flex max-w-4xl flex-col items-center text-center">
        {/* App icon */}
        <Image
          src="/app-icon.png"
          alt="VP Academy"
          width={96}
          height={96}
          className="mb-8 rounded-[22px] shadow-lg shadow-mint/10"
        />

        <h1 className="mb-6 text-4xl font-bold tracking-tight text-text-primary md:text-6xl">
          Play Smarter.{" "}
          <span className="text-mint">Win Better.</span>
        </h1>

        <p className="mb-10 max-w-2xl text-lg text-text-secondary md:text-xl">
          Master video poker strategy with structured lessons, real-time feedback,
          and a powerful hand analyzer. VP Academy is the training app serious
          players have been waiting for.
        </p>

        {/* App Store badge */}
        <a
          href={APP_STORE_URL}
          className="inline-flex items-center gap-3 rounded-full bg-mint px-8 py-4 text-lg font-semibold text-bg-primary transition-opacity hover:opacity-90"
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
          </svg>
          Download on the App Store
        </a>
      </div>
    </section>
  );
}
