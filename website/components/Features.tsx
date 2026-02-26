const features = [
  {
    title: "Training Lessons",
    description:
      "Step-by-step lessons that teach you optimal strategy, from basic hands to advanced plays.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <path d="M4 6h24v4H4zM4 14h18v4H4zM4 22h22v4H4z" fill="#6EEDC6" fillOpacity="0.8" />
        <circle cx="27" cy="24" r="3" fill="#6EEDC6" />
      </svg>
    ),
  },
  {
    title: "Play Mode",
    description:
      "Practice full video poker hands with real-time feedback on every decision you make.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <rect x="3" y="6" width="12" height="20" rx="2" fill="#6EEDC6" fillOpacity="0.6" />
        <rect x="17" y="6" width="12" height="20" rx="2" fill="#6EEDC6" />
      </svg>
    ),
  },
  {
    title: "Quiz Mode",
    description:
      "Test your knowledge with targeted quizzes that reinforce what you&apos;ve learned in lessons.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <circle cx="16" cy="16" r="12" stroke="#6EEDC6" strokeWidth="2.5" fill="none" />
        <text x="16" y="21" textAnchor="middle" fill="#6EEDC6" fontSize="16" fontWeight="bold">?</text>
      </svg>
    ),
  },
  {
    title: "Hand Analyzer",
    description:
      "Paste or deal any hand and see the mathematically optimal play with EV breakdowns.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <path d="M6 26V10l6 8 5-12 5 12 6-8v16z" fill="#6EEDC6" fillOpacity="0.7" />
      </svg>
    ),
  },
  {
    title: "Drills",
    description:
      "Focused repetition on the hands you miss most — build muscle memory for tough spots.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <circle cx="16" cy="16" r="12" stroke="#6EEDC6" strokeWidth="2" fill="none" />
        <circle cx="16" cy="16" r="7" stroke="#6EEDC6" strokeWidth="2" fill="none" />
        <circle cx="16" cy="16" r="2.5" fill="#6EEDC6" />
      </svg>
    ),
  },
  {
    title: "Mastery Dashboard",
    description:
      "Track your progress across lessons and drills. See where you excel and where to improve.",
    icon: (
      <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
        <rect x="4" y="18" width="5" height="10" rx="1" fill="#6EEDC6" fillOpacity="0.5" />
        <rect x="11.5" y="12" width="5" height="16" rx="1" fill="#6EEDC6" fillOpacity="0.7" />
        <rect x="19" y="6" width="5" height="22" rx="1" fill="#6EEDC6" fillOpacity="0.85" />
        <rect x="26.5" y="3" width="5" height="25" rx="1" fill="#6EEDC6" />
      </svg>
    ),
  },
];

export default function Features() {
  return (
    <section id="features" className="px-6 py-20 md:py-28">
      <div className="mx-auto max-w-6xl">
        <h2 className="mb-4 text-center text-3xl font-bold text-text-primary md:text-4xl">
          Everything You Need to Master Video Poker
        </h2>
        <p className="mx-auto mb-14 max-w-2xl text-center text-text-secondary">
          VP Academy combines structured learning with hands-on practice so you
          can play with confidence at every machine.
        </p>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.title}
              className="rounded-2xl border border-white/5 bg-bg-card p-6 transition-colors hover:border-mint/20"
            >
              <div className="mb-4">{feature.icon}</div>
              <h3 className="mb-2 text-lg font-semibold text-text-primary">
                {feature.title}
              </h3>
              <p className="text-sm leading-relaxed text-text-secondary">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
