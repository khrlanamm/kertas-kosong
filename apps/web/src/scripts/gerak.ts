/**
 * Gerak umum seluruh halaman:
 * - [data-muncul]    elemen masuk saat terlihat (nilai: kosong, "kiri", "kanan", "skala")
 * - [data-urut]      anak-anak elemen ini masuk bergantian
 * - .stabilo         coretan tergores saat terlihat
 * - [data-hitung]    angka menghitung naik saat terlihat
 *
 * Tanpa JavaScript semua isi tetap tampil, karena CSS-nya hanya aktif di bawah html.js.
 */

const kurangiGerak = matchMedia("(prefers-reduced-motion: reduce)").matches;

function terlihat(el: Element, panggil: () => void, rootMargin = "0px 0px -8% 0px") {
  const pengamat = new IntersectionObserver(
    (entri, p) => {
      if (entri.some((e) => e.isIntersecting)) {
        p.disconnect();
        panggil();
      }
    },
    { rootMargin, threshold: 0.1 },
  );
  pengamat.observe(el);
}

function siapkanMuncul() {
  document.querySelectorAll<HTMLElement>("[data-urut]").forEach((induk) => {
    [...induk.children].forEach((anak, i) => {
      const el = anak as HTMLElement;
      el.style.setProperty("--jeda", `${Math.min(i, 8) * 70}ms`);
      if (!el.hasAttribute("data-muncul")) el.setAttribute("data-muncul", "");
    });
  });
  document.querySelectorAll("[data-muncul]").forEach((el) => {
    terlihat(el, () => el.classList.add("terlihat"));
  });
  document.querySelectorAll(".stabilo").forEach((el) => {
    terlihat(el, () => el.classList.add("tergores"));
  });
}

function hitungNaik(el: HTMLElement) {
  const tujuan = Number(el.dataset.hitung);
  const desimal = Number(el.dataset.desimal ?? 0);
  const format = new Intl.NumberFormat("id-ID", { minimumFractionDigits: desimal, maximumFractionDigits: desimal });
  const akhir = format.format(tujuan);
  if (kurangiGerak || !Number.isFinite(tujuan)) return;

  const lama = 1300;
  let mulai = 0;
  el.textContent = format.format(0);
  const langkah = (waktu: number) => {
    mulai ||= waktu;
    const t = Math.min((waktu - mulai) / lama, 1);
    el.textContent = t === 1 ? akhir : format.format(tujuan * (1 - (1 - t) ** 3));
    if (t < 1) requestAnimationFrame(langkah);
  };
  requestAnimationFrame(langkah);
}

function siapkanHitung() {
  document.querySelectorAll<HTMLElement>("[data-hitung]").forEach((el) => {
    terlihat(el, () => hitungNaik(el), "0px");
  });
}

/** Cadangan garis progres untuk browser tanpa animation-timeline. */
function siapkanGarisBaca() {
  if (CSS.supports("animation-timeline: scroll()")) return;
  const garis = document.querySelector<HTMLElement>(".garis-baca");
  if (!garis) return;
  let menunggu = false;
  const perbarui = () => {
    menunggu = false;
    const akar = document.documentElement;
    garis.style.setProperty("--progres", String(akar.scrollTop / Math.max(1, akar.scrollHeight - akar.clientHeight)));
  };
  addEventListener(
    "scroll",
    () => {
      if (menunggu) return;
      menunggu = true;
      requestAnimationFrame(perbarui);
    },
    { passive: true },
  );
  perbarui();
}

siapkanMuncul();
siapkanHitung();
siapkanGarisBaca();
