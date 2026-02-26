import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "VP Academy — Play Smarter. Win Better.",
  description:
    "Master video poker strategy with VP Academy. Training lessons, play mode, hand analyzer, and more — all in one iOS app.",
  openGraph: {
    title: "VP Academy — Play Smarter. Win Better.",
    description:
      "Master video poker strategy with VP Academy. Training lessons, play mode, hand analyzer, and more — all in one iOS app.",
    url: "https://videopoker.academy",
    siteName: "VP Academy",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
