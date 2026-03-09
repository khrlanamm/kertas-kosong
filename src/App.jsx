import { BrowserRouter, Routes, Route } from "react-router-dom";
import Landing from "./pages/Landing";
import Tryout from "./pages/Tryout";
import PortalBimbel from "./pages/PortalBimbel";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/portal-bimbel" element={<PortalBimbel />} />
        <Route path="/tryout" element={<Tryout />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
