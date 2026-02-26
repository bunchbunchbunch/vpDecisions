import Image from "next/image";

export default function Footer() {
  return (
    <footer className="border-t border-white/10 px-6 py-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center gap-8 md:flex-row md:justify-between">
        {/* Logo */}
        <a href="/" className="flex items-center gap-2 text-lg font-semibold text-text-primary">
          <Image src="/app-icon.png" alt="VP Academy" width={24} height={24} className="rounded-md" />
          VP Academy
        </a>

        {/* Nav links */}
        <nav className="flex flex-wrap justify-center gap-6 text-sm text-text-secondary">
          <a href="#features" className="transition-colors hover:text-text-primary">Features</a>
          <a href="#screenshots" className="transition-colors hover:text-text-primary">Screenshots</a>
          <a href="#faq" className="transition-colors hover:text-text-primary">FAQ</a>
          <a href="/terms" className="transition-colors hover:text-text-primary">Terms</a>
          <a href="/privacy" className="transition-colors hover:text-text-primary">Privacy</a>
        </nav>

        {/* Copyright */}
        <p className="text-sm text-text-tertiary">
          &copy; {new Date().getFullYear()} VP Academy
        </p>
      </div>
    </footer>
  );
}
