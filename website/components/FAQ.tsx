"use client";

import { useState } from "react";

const faqs = [
  {
    question: "What is VP Academy?",
    answer:
      "VP Academy is an iOS app that teaches you mathematically optimal video poker strategy through structured lessons, practice hands, quizzes, and a powerful hand analyzer.",
  },
  {
    question: "Is VP Academy free?",
    answer:
      "VP Academy offers free content to get started. A premium subscription unlocks all lessons, advanced drills, and the full hand analyzer.",
  },
  {
    question: "What video poker games are supported?",
    answer:
      "VP Academy currently supports Jacks or Better, the most popular and foundational video poker variant. More game variants are on the roadmap.",
  },
  {
    question: "Do I need an internet connection?",
    answer:
      "Most features work offline once downloaded. Lessons, play mode, and the hand analyzer are all available without a connection.",
  },
  {
    question: "Who is VP Academy for?",
    answer:
      "Whether you're a complete beginner or an experienced player looking to sharpen your edge, VP Academy's progressive lesson structure meets you where you are.",
  },
  {
    question: "How is this different from other video poker apps?",
    answer:
      "VP Academy is focused on teaching, not gambling. Every feature is designed to help you understand why the optimal play is optimal — not just what it is.",
  },
];

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section id="faq" className="px-6 py-20 md:py-28">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-4 text-center text-3xl font-bold text-text-primary md:text-4xl">
          Frequently Asked Questions
        </h2>
        <p className="mx-auto mb-14 max-w-xl text-center text-text-secondary">
          Got questions? We&apos;ve got answers.
        </p>

        <div className="space-y-3">
          {faqs.map((faq, i) => (
            <div
              key={i}
              className="rounded-xl border border-white/5 bg-bg-card"
            >
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="flex w-full items-center justify-between px-6 py-5 text-left"
              >
                <span className="pr-4 font-medium text-text-primary">
                  {faq.question}
                </span>
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 20 20"
                  fill="none"
                  className={`shrink-0 text-text-tertiary transition-transform ${openIndex === i ? "rotate-180" : ""}`}
                >
                  <path
                    d="M5 7.5l5 5 5-5"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
              {openIndex === i && (
                <div className="px-6 pb-5 text-sm leading-relaxed text-text-secondary">
                  {faq.answer}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
