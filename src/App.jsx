import { BrowserRouter, Routes, Route } from "react-router-dom";
import Landing from "./pages/Landing";
import Tryout from "./pages/Tryout";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/tryout" element={<Tryout />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
