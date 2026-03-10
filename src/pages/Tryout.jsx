import { useEffect, useState } from "react";
import { db } from "../firebase";
import { collection, getDocs } from "firebase/firestore";
import { FileText, Clock, ChevronRight, Timer } from "lucide-react";
import { Link } from "react-router-dom";

export default function Tryout() {
  const [subtests, setSubtests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTryout, setActiveTryout] = useState(null);
  const [timeLeft, setTimeLeft] = useState({
    days: 0, hours: 0, minutes: 0, seconds: 0
  });

  useEffect(() => {
    document.title = "Sistem Tryout | Kertas Kosong";

    const fetchData = async () => {
      setLoading(true);
      try {
        // Fetch jadwal tryout
        const jadwalSnap = await getDocs(collection(db, "jadwal_tryout"));
        const now = new Date().getTime();
        let currentActive = null;

        jadwalSnap.forEach((doc) => {
          const data = doc.data();
          if (data.tanggal_mulai && data.tanggal_selesai) {
            const start = new Date(data.tanggal_mulai).getTime();
            const end = new Date(data.tanggal_selesai).getTime();
            if (now >= start && now <= end) {
              currentActive = { id: doc.id, ...data, end };
            }
          }
        });

        setActiveTryout(currentActive);

        // Only fetch subtests if there's an active tryout
        if (currentActive) {
          const querySnapshot = await getDocs(collection(db, "tryout"));
          const data = querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }));
          data.sort((a, b) => a.id.localeCompare(b.id));
          setSubtests(data);
        }
      } catch (error) {
        console.error("Error fetching tryout data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    if (!activeTryout) {
      setTimeLeft({ days: 0, hours: 0, minutes: 0, seconds: 0 });
      return;
    }

    const deadline = activeTryout.end;
    const interval = setInterval(() => {
      const now = new Date().getTime();
      const distance = deadline - now;
      if (distance < 0) {
        clearInterval(interval);
        setTimeLeft({ days: 0, hours: 0, minutes: 0, seconds: 0 });
      } else {
        setTimeLeft({
          days: Math.floor(distance / (1000 * 60 * 60 * 24)),
          hours: Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
          minutes: Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60)),
          seconds: Math.floor((distance % (1000 * 60)) / 1000)
        });
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [activeTryout]);

  return (
    <div className="min-h-screen bg-slate-50">
      <nav className="bg-white shadow-sm border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <Link to="/" className="flex items-center gap-3">
              <img src="/logo.png" alt="Logo" className="h-10 w-10 object-contain" />
              <span className="font-bold text-xl text-slate-800">#AyoKuliah 2026</span>
            </Link>
            <div className="text-sm font-medium text-slate-600 shadow-sm px-3 py-1 rounded-full border border-slate-200">
              Portal Tryout
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-slate-800"></div>
          </div>
        ) : !activeTryout ? (
          <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
            <div className="bg-slate-100 p-6 rounded-full mb-6">
              <Clock className="w-16 h-16 text-slate-400" />
            </div>
            <h2 className="text-3xl font-bold text-slate-800 mb-4">Waktu TryOut Belum Tiba</h2>
            <p className="text-slate-600 max-w-lg mb-8 text-lg">
              Saat ini tidak ada TryOut yang sedang berlangsung. Silakan cek kembali jadwal TryOut melalui Portal Dashboard Peserta sesuai dengan rentang waktu yang telah ditentukan.
            </p>
            <Link to="/portal-bimbel" className="bg-blue-600 hover:bg-blue-700 transition-colors text-white font-semibold py-3 px-8 rounded-lg shadow-sm">
              Kembali ke Dashboard
            </Link>
          </div>
        ) : (
          <div className="animate-in fade-in duration-300">
            <div className="mb-8 text-center md:text-left">
              <h1 className="text-3xl font-bold text-slate-800 mb-2">
                {activeTryout.nama || activeTryout.nama_tryout || "Daftar Subtes Tryout"}
              </h1>
              <p className="text-slate-600 mb-6">
                {activeTryout.deskripsi || "Pilih subtes di bawah ini untuk mulai mengerjakan. Kerjakan seluruh subtest tryout sebelum waktu berakhir."}
              </p>
              
              <div className="inline-flex flex-col md:flex-row items-center gap-4 bg-white px-6 py-4 rounded-xl shadow-sm border border-orange-200">
                <div className="flex items-center gap-2 text-orange-600 font-semibold">
                  <Timer className="w-5 h-5" />
                  <span>Sisa Waktu Pengerjaan:</span>
                </div>
                <div className="flex gap-2 sm:gap-3 text-center">
                  <div className="flex flex-col">
                    <span className="text-xl sm:text-2xl font-bold text-slate-800 bg-slate-100 px-2 sm:px-3 py-1 rounded-md">{String(timeLeft.days).padStart(2, '0')}</span>
                    <span className="text-xs text-slate-500 mt-1">Hari</span>
                  </div>
                  <span className="text-xl sm:text-2xl font-bold text-slate-800 py-1">:</span>
                  <div className="flex flex-col">
                    <span className="text-xl sm:text-2xl font-bold text-slate-800 bg-slate-100 px-2 sm:px-3 py-1 rounded-md">{String(timeLeft.hours).padStart(2, '0')}</span>
                    <span className="text-xs text-slate-500 mt-1">Jam</span>
                  </div>
                  <span className="text-xl sm:text-2xl font-bold text-slate-800 py-1">:</span>
                  <div className="flex flex-col">
                    <span className="text-xl sm:text-2xl font-bold text-slate-800 bg-slate-100 px-2 sm:px-3 py-1 rounded-md">{String(timeLeft.minutes).padStart(2, '0')}</span>
                    <span className="text-xs text-slate-500 mt-1">Menit</span>
                  </div>
                  <span className="text-xl sm:text-2xl font-bold text-slate-800 py-1">:</span>
                  <div className="flex flex-col">
                    <span className="text-xl sm:text-2xl font-bold text-slate-800 bg-slate-100 px-2 sm:px-3 py-1 rounded-md">{String(timeLeft.seconds).padStart(2, '0')}</span>
                    <span className="text-xs text-slate-500 mt-1">Detik</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {subtests.map((item) => (
              <div key={item.id} className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 flex flex-col transition-all hover:shadow-md hover:border-slate-300">
                <h3 className="text-xl font-bold text-slate-800 mb-4">{item.subtest || item.id}</h3>
                
                <div className="space-y-3 mb-8 flex-grow">
                  <div className="flex items-center text-slate-700 font-medium">
                    <FileText className="w-5 h-5 mr-3 text-slate-500" />
                    <span>{item.question ? `${item.question} Soal` : 'Jumlah soal tidak tersedia'}</span>
                  </div>
                  <div className="flex items-center text-slate-700 font-medium">
                    <Clock className="w-5 h-5 mr-3 text-slate-500" />
                    <span>{item.time ? `${item.time} Menit` : 'Waktu pengerjaan tidak tersedia'}</span>
                  </div>
                </div>

                <a
                  href={item.url || "#"}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full flex items-center justify-center bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors group"
                >
                  Kerjakan
                  <ChevronRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
                </a>
              </div>
            ))}
            
              {subtests.length === 0 && (
                <div className="col-span-full text-center py-12 bg-white rounded-xl border border-dashed border-slate-300">
                  <p className="text-slate-500 text-lg">Belum ada data subtes pada database Firestore.</p>
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
