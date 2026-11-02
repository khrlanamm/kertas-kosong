/**
 * Tab yang bisa dipakai ulang. Tandai dengan role="tablist", isi dengan button role="tab"
 * yang punya aria-controls, dan panel role="tabpanel". Panel aktif memakai class "aktif".
 * Tanpa JavaScript semua panel tampil berurutan.
 */
document.querySelectorAll<HTMLElement>('[role="tablist"]').forEach((daftar) => {
  const tab = [...daftar.querySelectorAll<HTMLButtonElement>('[role="tab"]')];

  const pilih = (terpilih: HTMLButtonElement, fokus = false) => {
    tab.forEach((t) => {
      const aktif = t === terpilih;
      t.setAttribute("aria-selected", String(aktif));
      t.tabIndex = aktif ? 0 : -1;
      document.getElementById(t.getAttribute("aria-controls") ?? "")?.classList.toggle("aktif", aktif);
    });
    if (fokus) terpilih.focus();
    daftar.dispatchEvent(new CustomEvent("ganti-tab", { detail: terpilih, bubbles: true }));
  };

  /** Tautan seperti /ayo-terlibat#donasi membuka panel yang berisi #donasi. */
  const dariTautan = () => {
    const el = location.hash ? document.getElementById(decodeURIComponent(location.hash.slice(1))) : null;
    const panel = el?.closest('[role="tabpanel"]');
    const terkait = tab.find((t) => t.getAttribute("aria-controls") === panel?.id);
    if (el && terkait) {
      pilih(terkait);
      requestAnimationFrame(() => el.scrollIntoView());
    }
  };
  dariTautan();
  addEventListener("hashchange", dariTautan);

  tab.forEach((t, i) => {
    t.addEventListener("click", () => pilih(t));
    t.addEventListener("keydown", (e) => {
      const tujuan: Record<string, number> = {
        ArrowRight: i + 1,
        ArrowDown: i + 1,
        ArrowLeft: i - 1,
        ArrowUp: i - 1,
        Home: 0,
        End: tab.length - 1,
      };
      if (!(e.key in tujuan)) return;
      e.preventDefault();
      pilih(tab[(tujuan[e.key] + tab.length) % tab.length], true);
    });
  });
});
