import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { db } from "../firebase";
import { collection, getDocs, doc, getDoc } from "firebase/firestore";
import { BookOpen, CalendarCheck, PenTool, ExternalLink, PlayCircle, Clock } from "lucide-react";

export default function PortalBimbel() {
  const [activeTab, setActiveTab] = useState("kelas");
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  // Data States
  const [linkAbstrak, setLinkAbstrak] = useState("");
  const [rekaman, setRekaman] = useState({});
  const [kehadiran, setKehadiran] = useState({ rekap: [], presensiA: [], presensiB: [] });
  const [jadwalTryout, setJadwalTryout] = useState([]);

  useEffect(() => {
    document.title = "Portal Bimbel | Kertas Kosong";
    
    const fetchPortalData = async () => {
      setLoading(true);
      try {
        // Fetch Tautan Penting (Link Abstrak)
        const docRef = doc(db, "tautan_penting", "LINK-ABSTRAK");
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          setLinkAbstrak(docSnap.data().url || "");
        }

        // Fetch Rekaman (Grouped by minggu)
        const rekamanSnap = await getDocs(collection(db, "rekaman"));
        const rekamanData = {};
        rekamanSnap.forEach((doc) => {
          const data = doc.data();
          const minggu = data.minggu || "Lainnya";
          if (!rekamanData[minggu]) rekamanData[minggu] = [];
          rekamanData[minggu].push({ id: doc.id, ...data });
        });
        setRekaman(rekamanData);

        // Fetch Kehadiran
        const kehadiranSnap = await getDocs(collection(db, "kehadiran"));
        const kehadiranData = { rekap: [], presensiA: [], presensiB: [] };
        kehadiranSnap.forEach((doc) => {
          const data = doc.data();
          if (data.kategori === "Rekap Ketidakhadiran") {
            kehadiranData.rekap.push({ id: doc.id, ...data });
          } else if (data.kategori === "Presensi" && data.kelas === "A") {
            kehadiranData.presensiA.push({ id: doc.id, ...data });
          } else if (data.kategori === "Presensi" && data.kelas === "B") {
            kehadiranData.presensiB.push({ id: doc.id, ...data });
          }
        });
        setKehadiran(kehadiranData);

        // Fetch Jadwal Tryout
        const tryoutSnap = await getDocs(collection(db, "jadwal_tryout"));
        const tryoutData = tryoutSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        // Urutkan jadwal tryout berdasarkan tanggal mulai
        tryoutData.sort((a, b) => new Date(a.tanggal_mulai) - new Date(b.tanggal_mulai));
        setJadwalTryout(tryoutData);

      } catch (error) {
        console.error("Error fetching data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchPortalData();
  }, []);

  const formatDate = (dateString) => {
    if (!dateString) return "";
    const options = { day: 'numeric', month: 'long', year: 'numeric' };
    return new Date(dateString).toLocaleDateString('id-ID', options);
  };

  const getTryoutStatus = (startStr, endStr) => {
    const now = new Date().getTime();
    if (!startStr || !endStr) return { active: false, label: "Jadwal Tidak Valid" };
    
    const start = new Date(startStr).getTime();
    const end = new Date(endStr).getTime();

    if (now < start) {
      return { active: false, label: "Belum Dibuka" };
    } else if (now > end) {
      return { active: false, label: "Ditutup" };
    } else {
      return { active: true, label: "Kerjakan Tryout" };
    }
  };

  return (
    <div className="min-h-screen bg-slate-50">
      <nav className="bg-white shadow-sm border-b border-slate-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <Link to="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
              <img src="/logo.png" alt="Logo Kertas Kosong" className="h-10 w-10 object-contain" />
              <span className="font-bold text-xl text-slate-800 hidden sm:block">#AyoKuliah 2026</span>
            </Link>
            <div className="text-sm font-semibold text-blue-600 bg-blue-50 px-4 py-1.5 rounded-full border border-blue-100">
              Dashboard Peserta
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Navigation Tabs */}
        <div className="flex bg-white rounded-xl shadow-sm border border-slate-200 p-1 mb-8 overflow-x-auto">
          <button
            onClick={() => setActiveTab("kelas")}
            className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium text-sm sm:text-base transition-all whitespace-nowrap ${
              activeTab === "kelas" 
                ? "bg-blue-600 text-white shadow-md" 
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
            }`}
          >
            <BookOpen className="w-5 h-5" />
            <span>Kelas & Rekaman</span>
          </button>
          
          <button
            onClick={() => setActiveTab("kehadiran")}
            className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium text-sm sm:text-base transition-all whitespace-nowrap ${
              activeTab === "kehadiran" 
                ? "bg-blue-600 text-white shadow-md" 
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
            }`}
          >
            <CalendarCheck className="w-5 h-5" />
            <span>Info Kehadiran</span>
          </button>
          
          <button
            onClick={() => setActiveTab("tryout")}
            className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium text-sm sm:text-base transition-all whitespace-nowrap ${
              activeTab === "tryout" 
                ? "bg-blue-600 text-white shadow-md" 
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
            }`}
          >
            <PenTool className="w-5 h-5" />
            <span>Jadwal Tryout</span>
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="animate-in fade-in duration-300">
            {/* TAB 1: KELAS */}
            {activeTab === "kelas" && (
              <div className="space-y-6">
                <div className="bg-blue-50 rounded-xl p-5 border border-blue-100 flex flex-col md:flex-row gap-5 items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-slate-800 mb-2">Instruksi Pengganti Kelas</h3>
                    <p className="text-slate-600 text-sm md:text-base">
                      Rekaman seluruh kelas dan kegiatan lengkap diunggah di YouTube Komunitas Kertas Kosong. 
                      Bagi peserta yang tidak hadir kelas atau izin, <strong>wajib menonton video rekaman lalu mengunggah Abstrak (Catatan/Rangkuman) pada formulir berikut.</strong>
                    </p>
                  </div>
                  {linkAbstrak && (
                    <a 
                      href={linkAbstrak} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="shrink-0 flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors shadow-sm w-full md:w-auto justify-center"
                    >
                      <PenTool className="w-4 h-4" />
                      Upload Abstrak
                    </a>
                  )}
                </div>

                <div className="mt-8">
                  <h2 className="text-2xl font-bold text-slate-800 mb-6 flex items-center gap-2">
                    <PlayCircle className="text-blue-600" />
                    Daftar Rekaman Kelas
                  </h2>
                  
                  {Object.keys(rekaman).length === 0 ? (
                    <div className="text-center py-10 bg-white rounded-xl border border-dashed border-slate-300">
                      <p className="text-slate-500">Belum ada rekaman kelas yang diunggah.</p>
                    </div>
                  ) : (
                    <div className="space-y-6">
                      {Object.keys(rekaman).sort().map((minggu) => (
                        <div key={minggu} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                          <div className="bg-slate-100 px-5 py-3 border-b border-slate-200 font-bold text-slate-700">
                            {minggu}
                          </div>
                          <div className="divide-y divide-slate-100">
                            {rekaman[minggu].map((item) => (
                              <div key={item.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between hover:bg-slate-50 transition-colors gap-4">
                                <div>
                                  <h4 className="font-semibold text-slate-800 text-lg">{item.kelas || item.judul || "Tanpa Judul"}</h4>
                                  {item.deskripsi && <p className="text-sm text-slate-500 mt-1">{item.deskripsi}</p>}
                                </div>
                                <a 
                                  href={item.url || "#"} 
                                  target="_blank" 
                                  rel="noopener noreferrer"
                                  className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-800 font-medium text-sm sm:w-auto w-fit"
                                >
                                  Tonton Rekaman <ExternalLink className="w-4 h-4" />
                                </a>
                              </div>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* TAB 2: KEHADIRAN */}
            {activeTab === "kehadiran" && (
              <div className="space-y-6">
                {/* Grup 1 */}
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                  <div className="bg-red-50 px-5 py-4 border-b border-red-100 flex items-center gap-3">
                    <CalendarCheck className="text-red-600 w-5 h-5" />
                    <h3 className="font-bold text-slate-800 text-lg">Rekap Ketidakhadiran (Alpha)</h3>
                  </div>
                  <div className="p-5 grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {kehadiran.rekap.length === 0 ? (
                      <p className="text-slate-500 text-sm col-span-full">Tidak ada link rekap ketidakhadiran.</p>
                    ) : (
                      kehadiran.rekap.map(item => (
                         <a key={item.id} href={item.url} target="_blank" rel="noopener noreferrer" className="flex items-center justify-between p-4 rounded-lg border border-slate-200 hover:border-red-300 hover:bg-red-50/50 transition-all group">
                           <span className="font-medium text-slate-700 group-hover:text-red-700">{item.nama || `Link Kelas ${item.kelas}`}</span>
                           <ExternalLink className="w-4 h-4 text-slate-400 group-hover:text-red-500" />
                         </a>
                      ))
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Grup 2: Presensi Kelas A */}
                  <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                    <div className="bg-emerald-50 px-5 py-4 border-b border-emerald-100 flex items-center gap-3">
                      <BookOpen className="text-emerald-600 w-5 h-5" />
                      <h3 className="font-bold text-slate-800 text-lg">Presensi Kelas A</h3>
                    </div>
                    <div className="p-4 flex flex-col gap-3">
                      {kehadiran.presensiA.length === 0 ? (
                        <p className="text-slate-500 text-sm p-2">Tidak ada data presensi Kelas A.</p>
                      ) : (
                        kehadiran.presensiA.map(item => (
                          <a key={item.id} href={item.url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition-colors border border-transparent hover:border-slate-200">
                             <div className="bg-emerald-100 text-emerald-700 w-8 h-8 rounded-full flex items-center justify-center shrink-0">
                               <PenTool className="w-4 h-4" />
                             </div>
                             <span className="font-medium text-slate-700">{item.nama || "Link Presensi"}</span>
                          </a>
                        ))
                      )}
                    </div>
                  </div>

                  {/* Grup 3: Presensi Kelas B */}
                  <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                    <div className="bg-blue-50 px-5 py-4 border-b border-blue-100 flex items-center gap-3">
                      <BookOpen className="text-blue-600 w-5 h-5" />
                      <h3 className="font-bold text-slate-800 text-lg">Presensi Kelas B</h3>
                    </div>
                    <div className="p-4 flex flex-col gap-3">
                      {kehadiran.presensiB.length === 0 ? (
                        <p className="text-slate-500 text-sm p-2">Tidak ada data presensi Kelas B.</p>
                      ) : (
                        kehadiran.presensiB.map(item => (
                          <a key={item.id} href={item.url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition-colors border border-transparent hover:border-slate-200">
                             <div className="bg-blue-100 text-blue-700 w-8 h-8 rounded-full flex items-center justify-center shrink-0">
                               <PenTool className="w-4 h-4" />
                             </div>
                             <span className="font-medium text-slate-700">{item.nama || "Link Presensi"}</span>
                          </a>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* TAB 3: TRYOUT */}
            {activeTab === "tryout" && (
              <div className="space-y-6">
                <div className="mb-6">
                  <h2 className="text-2xl font-bold text-slate-800 mb-2">Jadwal Ujian Tryout</h2>
                  <p className="text-slate-600">Pastikan kamu mengerjakan tryout sesuai dengan rentang waktu yang telah ditentukan.</p>
                </div>

                {jadwalTryout.length === 0 ? (
                   <div className="text-center py-12 bg-white rounded-xl border border-dashed border-slate-300">
                     <p className="text-slate-500 text-lg">Belum ada jadwal tryout yang dipublikasikan.</p>
                   </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {jadwalTryout.map(item => {
                      const status = getTryoutStatus(item.tanggal_mulai, item.tanggal_selesai);
                      
                      return (
                        <div key={item.id} className={`bg-white rounded-xl border p-6 flex flex-col transition-all ${status.active ? 'shadow-md border-blue-200' : 'shadow-sm border-slate-200 opacity-90'}`}>
                          <div className="flex justify-between items-start mb-4">
                            <h3 className="text-xl font-bold text-slate-800">{item.nama_tryout || item.id}</h3>
                            <span className={`text-xs font-bold px-3 py-1 rounded-full ${status.active ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'}`}>
                              {status.active ? 'Sedang Berlangsung' : (status.label === 'Belum Dibuka' ? 'Akan Datang' : 'Berakhir')}
                            </span>
                          </div>
                          
                          {item.deskripsi && (
                            <p className="text-slate-600 text-sm mb-6 flex-grow">{item.deskripsi}</p>
                          )}
                          
                          <div className="space-y-2 mb-6 mt-auto">
                            <div className="flex items-center gap-2 text-sm text-slate-500">
                              <Clock className="w-4 h-4" />
                              <span className="font-medium text-slate-700">Mulai:</span> 
                              {formatDate(item.tanggal_mulai)}
                            </div>
                            <div className="flex items-center gap-2 text-sm text-slate-500">
                              <Clock className="w-4 h-4 text-red-400" />
                              <span className="font-medium text-slate-700">Ditutup:</span> 
                              {formatDate(item.tanggal_selesai)}
                            </div>
                          </div>
                          
                          <button
                            onClick={() => status.active && navigate('/tryout')}
                            disabled={!status.active}
                            className={`w-full py-3 px-4 rounded-lg font-semibold flex justify-center items-center gap-2 transition-all ${
                              status.active 
                                ? 'bg-blue-600 hover:bg-blue-700 text-white shadow-sm cursor-pointer' 
                                : 'bg-slate-100 text-slate-400 cursor-not-allowed border border-slate-200'
                            }`}
                          >
                            <PenTool className="w-5 h-5" />
                            {status.label}
                          </button>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
