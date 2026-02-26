import Image from "next/image";

const screenshots = [
  { src: "/screenshots/01_home_screen.png", alt: "VP Academy home screen" },
  { src: "/screenshots/03_training_studyhall.png", alt: "Training study hall" },
  { src: "/screenshots/05_play_predraw.png", alt: "Play mode — pre-draw" },
  { src: "/screenshots/07_analyze.png", alt: "Hand analyzer" },
];

export default function Screenshots() {
  return (
    <section id="screenshots" className="px-6 py-20 md:py-28">
      <div className="mx-auto max-w-6xl">
        <h2 className="mb-4 text-center text-3xl font-bold text-text-primary md:text-4xl">
          See It in Action
        </h2>
        <p className="mx-auto mb-14 max-w-2xl text-center text-text-secondary">
          A clean, focused interface designed for learning — no clutter, no distractions.
        </p>

        <div className="grid grid-cols-2 gap-4 md:gap-6 lg:grid-cols-4">
          {screenshots.map((shot) => (
            <div
              key={shot.src}
              className="overflow-hidden rounded-2xl border border-white/5 bg-bg-card"
            >
              <Image
                src={shot.src}
                alt={shot.alt}
                width={390}
                height={844}
                className="h-auto w-full"
              />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
