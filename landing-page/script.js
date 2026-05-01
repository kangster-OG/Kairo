const revealItems = document.querySelectorAll("[data-reveal]");
const screens = document.querySelectorAll(".screen-image");
const scrollMeter = document.querySelector(".scroll-meter span");
const magneticItems = document.querySelectorAll(".magnetic");

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.18 },
);

revealItems.forEach((item, index) => {
  item.style.transitionDelay = `${Math.min(index * 50, 260)}ms`;
  revealObserver.observe(item);
});

let screenIndex = 0;
window.setInterval(() => {
  if (!screens.length) return;
  screens[screenIndex].classList.remove("is-active");
  screenIndex = (screenIndex + 1) % screens.length;
  screens[screenIndex].classList.add("is-active");
}, 3200);

const updateScrollProgress = () => {
  const scrollable = document.documentElement.scrollHeight - window.innerHeight;
  const progress = scrollable > 0 ? (window.scrollY / scrollable) * 100 : 0;
  scrollMeter?.style.setProperty("--scroll-progress", `${progress}%`);
};

window.addEventListener("scroll", updateScrollProgress, { passive: true });
window.addEventListener("resize", updateScrollProgress);
updateScrollProgress();

magneticItems.forEach((item) => {
  item.addEventListener("pointermove", (event) => {
    const rect = item.getBoundingClientRect();
    const x = event.clientX - rect.left - rect.width / 2;
    const y = event.clientY - rect.top - rect.height / 2;
    item.style.transform = `translate(${x * 0.08}px, ${y * 0.12}px)`;
  });

  item.addEventListener("pointerleave", () => {
    item.style.transform = "";
  });
});

document.querySelector(".waitlist-form")?.addEventListener("submit", (event) => {
  event.preventDefault();
  const button = event.currentTarget.querySelector("button span:first-child");
  if (!button) return;
  button.textContent = "Requested";
});
