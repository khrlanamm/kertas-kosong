import { useEffect, useState } from "react";
import { db } from "../firebase";
import { collection, getDocs } from "firebase/firestore";
import { FileText, Clock, ChevronRight, Timer } from "lucide-react";
import { Link } from "react-router-dom";

export default function Tryout() {
  const [subtests, setSubtests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [timeLeft, setTimeLeft] = useState({
    days: 0, hours: 0, minutes: 0, seconds: 0
  });

  useEffect(() => {
    document.title = "Sistem Tryout | Kertas Kosong";
    const deadline = new Date("2026-03-09T23:59:00+07:00").getTime();
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
  }, []);

  useEffect(() => {
    const fetchTryoutData = async () => {
      try {
        const querySnapshot = await getDocs(collection(db, "tryout"));
        const data = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        data.sort((a, b) => a.id.localeCompare(b.id));
        setSubtests(data);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };

    fetchTryoutData();
  }, []);

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
        <div className="mb-8 text-center md:text-left">
          <h1 className="text-3xl font-bold text-slate-800 mb-2">Daftar Subtes Tryout</h1>
          <p className="text-slate-600 mb-6">Pilih subtes di bawah ini untuk mulai mengerjakan. Kerjakan seluruh subtest tryout sebelum waktu berakhir.</p>
          
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

        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-slate-800"></div>
          </div>
        ) : (
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
            
            {subtests.length === 0 && !loading && (
              <div className="col-span-full text-center py-12 bg-white rounded-xl border border-dashed border-slate-300">
                <p className="text-slate-500 text-lg">Belum ada data subtes pada database Firestore.</p>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
