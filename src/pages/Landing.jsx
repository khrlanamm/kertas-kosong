import { useEffect } from "react";
import { Link } from "react-router-dom";

export default function Landing() {
  useEffect(() => {
    document.title = "Komunitas Kertas Kosong";
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-4">
      <div className="text-center max-w-2xl mx-auto">
        <img src="/logo.png" alt="Logo Kertas Kosong" className="w-32 h-32 mx-auto mb-8 object-contain" />
        <h1 className="text-4xl md:text-5xl font-bold text-slate-800 mb-6">
          Halaman Utama Komunitas Kertas Kosong
        </h1>
        <p className="text-xl text-slate-600 mb-10">
          (Coming Soon)
        </p>
        <Link
          to="/portal-bimbel"
          className="inline-block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-4 px-8 rounded-lg transition-colors duration-200 shadow-md hover:shadow-lg"
        >
          Masuk ke Portal Bimbel
        </Link>
      </div>
    </div>
  );
}
