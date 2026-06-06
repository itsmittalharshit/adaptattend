'use client';
import { useState, useRef, useEffect, createContext, useContext } from 'react';
import { motion, useInView, AnimatePresence, useMotionValue, useTransform } from 'framer-motion';
import {
  MapPin, ScanFace, BarChart3, Clock, Users,
  ChevronRight, CheckCircle2, Smartphone, Database,
  ArrowRight, Send, Github, Linkedin, Mail, Menu, X,
  Lock, Globe, TrendingUp, Sun, Moon, Hash, WifiOff,
  Zap, Code2, Star, ExternalLink, Fingerprint,
} from 'lucide-react';

// ── Theme context ─────────────────────────────────────────────────────────────
const ThemeCtx = createContext({ isDark: true, toggle: () => {} });
const useTheme = () => useContext(ThemeCtx);

// ── Fade-in animation ─────────────────────────────────────────────────────────
function FadeIn({ children, delay = 0, className = '' }: {
  children: React.ReactNode; delay?: number; className?: string;
}) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: '-60px' });
  return (
    <motion.div ref={ref}
      initial={{ opacity: 0, y: 28 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.65, delay, ease: [0.22, 1, 0.36, 1] }}
      className={className}
    >{children}</motion.div>
  );
}

// ── Animated counter ──────────────────────────────────────────────────────────
function Counter({ to, suffix = '' }: { to: number; suffix?: string }) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (!inView) return;
    let start = 0;
    const step = Math.ceil(to / 40);
    const timer = setInterval(() => {
      start += step;
      if (start >= to) { setCount(to); clearInterval(timer); }
      else setCount(start);
    }, 30);
    return () => clearInterval(timer);
  }, [inView, to]);
  return <span ref={ref}>{count}{suffix}</span>;
}

// ── Nav links ─────────────────────────────────────────────────────────────────
const NAV_LINKS = [
  { label: 'Features',    href: '#features' },
  { label: 'How It Works', href: '#how-it-works' },
  { label: 'Tech Stack',  href: '#tech' },
  { label: 'Contact',     href: '#contact' },
];

// ── Attendance methods (accurate) ─────────────────────────────────────────────
const METHODS = [
  {
    icon: Hash,
    title: '6-Digit TOTP Code',
    desc: 'Manager\'s screen shows a rotating 6-digit code, refreshing every 15 seconds. Employee types it in — expired codes are instantly rejected. No internet, no QR scanner app.',
    color: 'from-violet-500 to-purple-600',
    pill: 'Anti-replay', pillColor: 'bg-violet-500/10 text-violet-400 border-violet-500/20',
    detail: ['15-second rotation window', 'HMAC-SHA1 offline algorithm', 'Works with zero internet', 'Auto-expires — no reuse'],
  },
  {
    icon: MapPin,
    title: 'GPS Geofencing',
    desc: 'Employee must be inside the configured office boundary. Distance is checked with the Haversine formula locally — no API call, no VPN bypass, no spoofing.',
    color: 'from-cyan-500 to-blue-600',
    pill: 'Location-locked', pillColor: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/20',
    detail: ['Manager-configurable radius', 'Haversine offline formula', 'Works on any Android device', 'Graceful GPS timeout fallback'],
  },
  {
    icon: ScanFace,
    title: 'Manager Face Scan',
    desc: 'Manager scans the employee\'s face on the manager\'s own device. LBP recognition runs 100% on-device — no server, no cloud upload. Employee can\'t fake from home.',
    color: 'from-emerald-500 to-teal-600',
    pill: 'On-device AI', pillColor: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
    detail: ['LBP histogram matching', 'Google ML Kit detection', 'Runs on manager\'s device', 'Zero cloud dependency'],
  },
];

// ── Stats (accurate) ──────────────────────────────────────────────────────────
const STATS = [
  { icon: WifiOff, label: 'Offline', value: '100', suffix: '%', sub: 'No internet required' },
  { icon: Clock,   label: 'QR Window', value: 15,  suffix: 's', sub: 'TOTP rotation interval' },
  { icon: Users,   label: 'Methods',   value: 3,   suffix: '',  sub: 'Code · GPS · Face' },
  { icon: Zap,     label: 'Servers',   value: 0,   suffix: '',  sub: 'Fully on-device' },
];

// ── How it works (accurate) ───────────────────────────────────────────────────
const HOW_IT_WORKS = [
  {
    step: '01', role: 'Manager', color: 'from-amber-500 to-orange-500',
    title: 'Set up in seconds',
    desc: 'Create an org, add employees, upload their profile photos (face embeddings are computed on-device), set office location, and choose which attendance methods to enable.',
  },
  {
    step: '02', role: 'Employee', color: 'from-indigo-500 to-violet-600',
    title: 'Mark attendance — your way',
    desc: 'Enter the 6-digit code from the manager\'s screen, tap GPS check-in while inside the office boundary, or walk up to the manager\'s device for a quick face scan.',
  },
  {
    step: '03', role: 'Manager', color: 'from-emerald-500 to-teal-600',
    title: 'Analyse with rich dashboards',
    desc: 'Daily attendance heatmaps, punctuality trends, per-employee breakdowns, and method usage stats — all stored locally in SQLite, no cloud sync needed.',
  },
];

// ── Tech stack (accurate) ─────────────────────────────────────────────────────
const TECH_STACK = [
  {
    category: 'Flutter App', icon: Smartphone, color: 'from-blue-500 to-indigo-600',
    items: ['Flutter 3 / Dart', 'Drift ORM (SQLite)', 'go_router navigation', 'Material 3 design system', 'ValueNotifier theming'],
  },
  {
    category: 'On-Device AI', icon: Fingerprint, color: 'from-emerald-500 to-teal-600',
    items: ['Google ML Kit face detect', 'LBP histogram (256-bin)', 'Cosine similarity matching', 'image pkg — crop / resize', 'SharedPreferences storage'],
  },
  {
    category: 'Offline Security', icon: Lock, color: 'from-violet-500 to-purple-600',
    items: ['HMAC-SHA1 TOTP tokens', 'Haversine geofence check', 'Drift SQLite on-device', 'Geolocator + permissions', 'uuid + crypto packages'],
  },
];

// ── Feature grid (accurate) ───────────────────────────────────────────────────
const FEATURES = [
  { icon: WifiOff,    title: 'Truly offline',         desc: 'Every feature — TOTP, GPS, face scan — works with zero internet.' },
  { icon: Hash,       title: 'Rotating TOTP codes',   desc: '15-second windows, HMAC-SHA1 — same algorithm as Google Authenticator.' },
  { icon: Globe,      title: 'Geofence attendance',   desc: 'Haversine formula offline — configurable radius, no GPS spoofing.' },
  { icon: Fingerprint,title: 'On-device face AI',     desc: 'LBP + ML Kit — recognition runs on the phone, no server involved.' },
  { icon: TrendingUp, title: 'Rich analytics',        desc: 'Daily heatmaps, punctuality scores, method breakdowns — all local.' },
  { icon: Database,   title: 'Drift + SQLite',        desc: 'Type-safe ORM, reactive streams, 30-day demo data pre-seeded.' },
];

// ── Floating particles (client-only to avoid hydration mismatch) ──────────────
type Particle = { id: number; x: number; y: number; size: number; dur: number; delay: number };
function Particles({ count = 18 }: { count?: number }) {
  const [particles, setParticles] = useState<Particle[]>([]);
  useEffect(() => {
    setParticles(Array.from({ length: count }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      size: Math.random() * 3 + 1,
      dur: Math.random() * 12 + 8,
      delay: Math.random() * 6,
    })));
  }, [count]);
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {particles.map(p => (
        <motion.div key={p.id}
          className="absolute rounded-full bg-indigo-400/20"
          style={{ left: `${p.x}%`, top: `${p.y}%`, width: p.size, height: p.size }}
          animate={{ y: [0, -40, 0], opacity: [0, 0.6, 0] }}
          transition={{ duration: p.dur, delay: p.delay, repeat: Infinity, ease: 'easeInOut' }}
        />
      ))}
    </div>
  );
}

// ── Tilt card ─────────────────────────────────────────────────────────────────
function TiltCard({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const rotateX = useTransform(y, [-0.5, 0.5], [4, -4]);
  const rotateY = useTransform(x, [-0.5, 0.5], [-4, 4]);

  const handleMove = (e: React.MouseEvent) => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    x.set((e.clientX - rect.left) / rect.width - 0.5);
    y.set((e.clientY - rect.top) / rect.height - 0.5);
  };
  const handleLeave = () => { x.set(0); y.set(0); };

  return (
    <motion.div ref={ref} style={{ rotateX, rotateY, transformStyle: 'preserve-3d' }}
      onMouseMove={handleMove} onMouseLeave={handleLeave}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className={className}>
      {children}
    </motion.div>
  );
}

// ── Scrolling tech ticker ─────────────────────────────────────────────────────
const TICKER_ITEMS = [
  'Flutter 3', 'Dart', 'Drift ORM', 'SQLite', 'Google ML Kit',
  'LBP Face AI', 'TOTP Offline', 'Haversine GPS', 'Material 3',
  'go_router', 'Geolocator', 'SharedPrefs', 'image_picker',
];
function TechTicker() {
  const { isDark } = useTheme();
  const items = [...TICKER_ITEMS, ...TICKER_ITEMS];
  return (
    <div className={`relative overflow-hidden py-3 border-y ${isDark ? 'border-white/5' : 'border-gray-200'}`}>
      <div className={`absolute left-0 top-0 w-16 h-full z-10 ${isDark ? 'bg-gradient-to-r from-gray-950' : 'bg-gradient-to-r from-slate-50'} to-transparent`} />
      <div className={`absolute right-0 top-0 w-16 h-full z-10 ${isDark ? 'bg-gradient-to-l from-gray-950' : 'bg-gradient-to-l from-slate-50'} to-transparent`} />
      <motion.div className="flex gap-6 w-max"
        animate={{ x: ['0%', '-50%'] }}
        transition={{ duration: 22, ease: 'linear', repeat: Infinity }}>
        {items.map((item, i) => (
          <span key={i} className={`text-xs font-medium px-3 py-1 rounded-full border whitespace-nowrap ${
            isDark ? 'bg-gray-900/60 border-white/8 text-gray-400' : 'bg-white border-gray-200 text-gray-500'
          }`}>
            {item}
          </span>
        ))}
      </motion.div>
    </div>
  );
}

// ── Navbar ────────────────────────────────────────────────────────────────────
function Navbar() {
  const { isDark, toggle } = useTheme();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener('scroll', fn);
    return () => window.removeEventListener('scroll', fn);
  }, []);

  const navBg = scrolled
    ? isDark
      ? 'bg-gray-950/90 backdrop-blur-xl border-b border-white/5 shadow-xl shadow-black/20'
      : 'bg-white/95 backdrop-blur-xl border-b border-gray-200 shadow-lg'
    : '';

  return (
    <nav className={`fixed top-0 w-full z-50 transition-all duration-300 ${navBg}`}>
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#" className="flex items-center gap-2.5 font-bold text-lg">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shadow-lg shadow-indigo-500/25">
            <ScanFace size={17} className="text-white" />
          </div>
          <span className={isDark
            ? 'bg-gradient-to-r from-white to-gray-400 bg-clip-text text-transparent'
            : 'text-gray-900'}>
            AdaptAttend
          </span>
        </a>
        <div className="hidden md:flex items-center gap-8">
          {NAV_LINKS.map(l => (
            <a key={l.label} href={l.href}
              className={`text-sm transition-colors duration-200 ${isDark ? 'text-gray-400 hover:text-white' : 'text-gray-500 hover:text-gray-900'}`}>
              {l.label}
            </a>
          ))}
        </div>
        <div className="hidden md:flex items-center gap-2">
          <a href="https://github.com/itsmittalharshit" target="_blank" rel="noopener noreferrer"
            className={`p-2 rounded-lg transition-colors ${isDark ? 'text-gray-500 hover:text-white hover:bg-white/5' : 'text-gray-400 hover:text-gray-900 hover:bg-gray-100'}`}
            title="GitHub">
            <Github size={18} />
          </a>
          <button onClick={toggle}
            className={`p-2 rounded-lg transition-all duration-200 ${isDark
              ? 'text-gray-400 hover:text-amber-400 hover:bg-amber-400/10'
              : 'text-gray-500 hover:text-indigo-600 hover:bg-indigo-50'}`}
            title={isDark ? 'Switch to light' : 'Switch to dark'}>
            {isDark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <a href="https://github.com/itsmittalharshit/adaptattend" target="_blank" rel="noopener noreferrer"
            className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm px-4 py-2 rounded-lg transition font-medium shadow-lg shadow-indigo-600/20">
            <Github size={15} /> View Source
          </a>
        </div>
        <div className="flex items-center gap-2 md:hidden">
          <button onClick={toggle} className={`p-2 rounded-lg ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            {isDark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button className={`p-2 ${isDark ? 'text-gray-400' : 'text-gray-500'}`} onClick={() => setOpen(!open)}>
            {open ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>
      <AnimatePresence>
        {open && (
          <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}
            className={`md:hidden border-b overflow-hidden ${isDark ? 'bg-gray-950 border-white/5' : 'bg-white border-gray-200'}`}>
            <div className="px-6 py-4 space-y-3">
              {NAV_LINKS.map(l => (
                <a key={l.label} href={l.href} onClick={() => setOpen(false)}
                  className={`block text-sm py-1 ${isDark ? 'text-gray-400 hover:text-white' : 'text-gray-500 hover:text-gray-900'}`}>
                  {l.label}
                </a>
              ))}
              <a href="https://github.com/itsmittalharshit/adaptattend" target="_blank" rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 bg-indigo-600 text-white text-sm px-4 py-2 rounded-lg mt-2">
                <Github size={14} /> View Source
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
}

// ── Phone mockup (accurate screens) ──────────────────────────────────────────
function PhoneMockup() {
  const [activeTab, setActiveTab] = useState(0);
  const tabs = ['TOTP Code', 'GPS Check', 'Face Scan'];
  useEffect(() => {
    const t = setInterval(() => setActiveTab(i => (i + 1) % 3), 3000);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="relative mx-auto w-64">
      <div className="relative bg-gray-900 rounded-[2.5rem] border-4 border-gray-700 shadow-2xl shadow-black/60 overflow-hidden" style={{ aspectRatio: '9/19' }}>
        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-20 h-5 bg-black rounded-full z-20" />
        <div className="h-full bg-gray-950 pt-10 px-4 pb-6 flex flex-col">
          <div className="flex justify-between text-[9px] text-gray-600 mb-4 px-1"><span>9:41</span><span>●●●</span></div>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-7 h-7 rounded-xl bg-indigo-600 flex items-center justify-center">
              <ScanFace size={14} className="text-white" />
            </div>
            <span className="text-white text-xs font-bold">AdaptAttend</span>
            <span className="ml-auto text-[9px] text-emerald-400 bg-emerald-400/10 px-2 py-0.5 rounded-full">● Offline</span>
          </div>
          <div className="flex gap-1 mb-4 bg-gray-900 p-1 rounded-xl">
            {tabs.map((tab, i) => (
              <button key={tab} onClick={() => setActiveTab(i)}
                className={`flex-1 text-[8px] py-1 rounded-lg transition-all ${activeTab === i ? 'bg-indigo-600 text-white' : 'text-gray-500'}`}>
                {tab}
              </button>
            ))}
          </div>
          <AnimatePresence mode="wait">
            <motion.div key={activeTab} initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}
              transition={{ duration: 0.3 }} className="flex-1 flex flex-col items-center justify-center gap-3 px-1">
              {activeTab === 0 && (
                <>
                  <p className="text-gray-400 text-[9px]">Enter manager's code</p>
                  <div className="flex gap-1.5">
                    {['4','8','2','9','1','7'].map((d, i) => (
                      <motion.div key={i} initial={{ scale: 0.8, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }} transition={{ delay: i * 0.08 }}
                        className="w-8 h-10 rounded-lg bg-gray-800 border border-indigo-500/40 flex items-center justify-center text-white font-bold text-base">
                        {d}
                      </motion.div>
                    ))}
                  </div>
                  <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden mt-1">
                    <motion.div className="h-full bg-indigo-500 rounded-full"
                      initial={{ width: '100%' }} animate={{ width: '0%' }}
                      transition={{ duration: 15, ease: 'linear', repeat: Infinity }} />
                  </div>
                  <p className="text-gray-600 text-[8px]">Refreshes every 15 seconds</p>
                </>
              )}
              {activeTab === 1 && (
                <>
                  <div className="w-24 h-24 rounded-full bg-cyan-500/10 border-2 border-cyan-500/30 flex items-center justify-center relative">
                    <MapPin size={28} className="text-cyan-400" />
                    <motion.div className="absolute inset-0 rounded-full border-2 border-cyan-400/30"
                      animate={{ scale: [1, 1.5], opacity: [0.5, 0] }}
                      transition={{ duration: 1.6, repeat: Infinity }} />
                    <motion.div className="absolute inset-0 rounded-full border-2 border-cyan-400/20"
                      animate={{ scale: [1, 1.9], opacity: [0.3, 0] }}
                      transition={{ duration: 1.6, delay: 0.4, repeat: Infinity }} />
                  </div>
                  <p className="text-emerald-400 text-[10px] font-semibold">✓ Inside office boundary</p>
                  <div className="bg-emerald-600 text-white text-[9px] px-5 py-1.5 rounded-lg font-semibold cursor-pointer">Check In</div>
                </>
              )}
              {activeTab === 2 && (
                <>
                  <div className="w-24 h-24 rounded-2xl bg-gray-900 border border-emerald-500/30 flex items-center justify-center relative overflow-hidden">
                    <ScanFace size={36} className="text-emerald-400" />
                    <motion.div className="absolute left-2 right-2 h-0.5 bg-emerald-400/50 rounded"
                      animate={{ top: ['15%', '85%', '15%'] }}
                      transition={{ duration: 2.2, repeat: Infinity, ease: 'easeInOut' }} style={{ position: 'absolute' }} />
                  </div>
                  <p className="text-white text-[10px] font-semibold">Manager scanning…</p>
                  <p className="text-emerald-400 text-[9px]">On-device · No cloud</p>
                  <div className="flex gap-1 mt-1">
                    {[1,2,3].map(i => (
                      <motion.div key={i} className="w-1.5 h-1.5 rounded-full bg-emerald-400"
                        animate={{ scale: [1, 1.5, 1], opacity: [0.4, 1, 0.4] }}
                        transition={{ duration: 1, delay: i * 0.2, repeat: Infinity }} />
                    ))}
                  </div>
                </>
              )}
            </motion.div>
          </AnimatePresence>
          <div className="flex justify-around mt-3 pt-3 border-t border-gray-800">
            {['🏠', '📊', '⚙️'].map(e => <button key={e} className="text-sm">{e}</button>)}
          </div>
        </div>
      </div>
      <div className="absolute inset-0 -z-10 bg-indigo-600/15 blur-3xl rounded-full scale-75" />
    </div>
  );
}

// ── Typing cycle text ─────────────────────────────────────────────────────────
const CYCLE_WORDS = ['TOTP codes', 'GPS geofencing', 'face recognition'];
function CycleText() {
  const [idx, setIdx] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setIdx(i => (i + 1) % CYCLE_WORDS.length), 2800);
    return () => clearInterval(t);
  }, []);
  return (
    <AnimatePresence mode="wait">
      <motion.span key={idx}
        initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -12 }}
        transition={{ duration: 0.4 }}
        className="bg-gradient-to-r from-indigo-400 via-violet-400 to-cyan-400 bg-clip-text text-transparent">
        {CYCLE_WORDS[idx]}
      </motion.span>
    </AnimatePresence>
  );
}

// ── Hero ──────────────────────────────────────────────────────────────────────
function HeroSection() {
  const { isDark } = useTheme();
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-indigo-600/20 rounded-full blur-3xl" />
        <div className="absolute bottom-1/3 right-1/4 w-72 h-72 bg-violet-600/15 rounded-full blur-3xl" />
        <div className="absolute top-1/2 right-1/3 w-48 h-48 bg-cyan-600/10 rounded-full blur-3xl" />
        {isDark && (
          <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.015)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.015)_1px,transparent_1px)] bg-[size:72px_72px]" />
        )}
        <Particles />
      </div>
      <div className="relative max-w-5xl mx-auto px-6 text-center">
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 bg-indigo-500/10 border border-indigo-500/25 text-indigo-400 text-xs px-4 py-2 rounded-full mb-8">
          <span className="w-1.5 h-1.5 rounded-full bg-indigo-400 animate-pulse" />
          100% Offline · Flutter · On-device AI · Portfolio Project
        </motion.div>

        <motion.h1 initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.1 }}
          className="text-5xl md:text-7xl font-black leading-[1.05] tracking-tight mb-6">
          Attendance that<br />can&apos;t be faked
        </motion.h1>

        <motion.p initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.2 }}
          className={`text-xl max-w-2xl mx-auto mb-4 leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-600'}`}>
          Secure attendance via&nbsp;
          <span className="inline-block min-w-[160px] text-left"><CycleText /></span>
        </motion.p>
        <motion.p initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.25 }}
          className={`text-sm max-w-xl mx-auto mb-10 ${isDark ? 'text-gray-600' : 'text-gray-400'}`}>
          A full-stack Flutter app — no backend, no cloud, no dependency.
          Every feature runs locally on Android.
        </motion.p>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.3 }}
          className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-20">
          <a href="https://github.com/itsmittalharshit/adaptattend" target="_blank" rel="noopener noreferrer"
            className="group inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-8 py-4 rounded-xl font-semibold text-base transition shadow-lg shadow-indigo-600/25">
            <Github size={18} /> View on GitHub
            <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
          </a>
          <a href="#features"
            className={`inline-flex items-center gap-2 border px-8 py-4 rounded-xl font-semibold text-base transition ${
              isDark
                ? 'border-white/10 hover:border-white/20 text-gray-300 hover:text-white'
                : 'border-gray-300 hover:border-gray-400 text-gray-600 hover:text-gray-900'
            }`}>
            Explore features
          </a>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 60 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1, delay: 0.5 }}
          className="relative mx-auto w-72">
          <div className={`absolute inset-x-0 bottom-0 h-1/2 z-10 ${isDark ? 'bg-gradient-to-t from-gray-950' : 'bg-gradient-to-t from-slate-50'} to-transparent`} />
          <PhoneMockup />
        </motion.div>
      </div>
    </section>
  );
}

// ── Stats ─────────────────────────────────────────────────────────────────────
function StatsSection() {
  const { isDark } = useTheme();
  return (
    <section className={`py-16 border-y ${isDark ? 'border-white/5 bg-gray-900/30' : 'border-gray-200 bg-gray-100/60'}`}>
      <div className="max-w-5xl mx-auto px-6 grid grid-cols-2 md:grid-cols-4 gap-8">
        {STATS.map(({ icon: Icon, label, value, suffix, sub }, i) => (
          <FadeIn key={label} delay={i * 0.1} className="text-center">
            <Icon className="mx-auto mb-3 text-indigo-400" size={22} />
            <div className={`text-3xl font-black mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              {typeof value === 'number' ? <Counter to={value} suffix={suffix} /> : `${value}${suffix}`}
            </div>
            <div className={`text-sm font-medium ${isDark ? 'text-gray-300' : 'text-gray-700'}`}>{label}</div>
            <div className={`text-xs mt-0.5 ${isDark ? 'text-gray-600' : 'text-gray-400'}`}>{sub}</div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

// ── Features ──────────────────────────────────────────────────────────────────
function FeaturesSection() {
  const { isDark } = useTheme();
  const [active, setActive] = useState(0);
  const method = METHODS[active];
  return (
    <section id="features" className="py-28 px-6">
      <div className="max-w-7xl mx-auto">
        <FadeIn className="text-center mb-16">
          <span className="text-indigo-400 text-sm font-semibold tracking-widest uppercase">Attendance Methods</span>
          <h2 className={`text-4xl md:text-5xl font-black mt-3 mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            Three ways to mark. Zero ways to fake.
          </h2>
          <p className={`max-w-xl mx-auto ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            Each method is independently hardened and works fully offline. Enable one, two, or all three.
          </p>
        </FadeIn>

        <div className="flex flex-col lg:flex-row gap-8">
          <div className="lg:w-1/3 flex flex-col gap-3">
            {METHODS.map((m, i) => {
              const Icon = m.icon;
              return (
                <button key={m.title} onClick={() => setActive(i)}
                  className={`text-left p-5 rounded-2xl border transition-all duration-300 ${
                    active === i
                      ? 'border-indigo-500/50 bg-indigo-500/10 shadow-lg shadow-indigo-500/10'
                      : isDark
                        ? 'border-white/5 bg-gray-900/50 hover:border-white/10'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                  }`}>
                  <div className="flex items-center gap-3 mb-2">
                    <div className={`w-9 h-9 rounded-xl bg-gradient-to-br ${m.color} flex items-center justify-center shadow-sm`}>
                      <Icon size={17} className="text-white" />
                    </div>
                    <span className={`font-semibold text-sm ${isDark ? 'text-white' : 'text-gray-900'}`}>{m.title}</span>
                    {active === i && <ChevronRight size={14} className="ml-auto text-indigo-400" />}
                  </div>
                  <p className={`text-xs leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{m.desc}</p>
                </button>
              );
            })}
          </div>

          <AnimatePresence mode="wait">
            <motion.div key={active} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
              className={`lg:flex-1 border rounded-2xl p-8 flex flex-col justify-between ${
                isDark ? 'bg-gray-900/50 border-white/5' : 'bg-white border-gray-200'
              }`}>
              <div>
                <span className={`inline-block text-xs px-3 py-1 rounded-full border font-medium mb-6 ${method.pillColor}`}>{method.pill}</span>
                <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${method.color} flex items-center justify-center mb-5 shadow-lg`}>
                  <method.icon size={28} className="text-white" />
                </div>
                <h3 className={`text-2xl font-bold mb-3 ${isDark ? 'text-white' : 'text-gray-900'}`}>{method.title}</h3>
                <p className={`leading-relaxed mb-8 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{method.desc}</p>
              </div>
              <ul className="grid grid-cols-2 gap-3">
                {method.detail.map(d => (
                  <li key={d} className={`flex items-center gap-2 text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>
                    <CheckCircle2 size={14} className="text-indigo-400 shrink-0" />{d}
                  </li>
                ))}
              </ul>
            </motion.div>
          </AnimatePresence>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-12">
          {FEATURES.map(({ icon: Icon, title, desc }, i) => (
            <FadeIn key={title} delay={i * 0.07}>
              <TiltCard className={`flex gap-4 p-5 border rounded-2xl transition-colors cursor-default ${
                isDark ? 'bg-gray-900/50 border-white/5 hover:border-indigo-500/20' : 'bg-white border-gray-200 hover:border-indigo-300'
              }`}>
                <div className="w-9 h-9 rounded-xl bg-indigo-500/15 border border-indigo-500/20 flex items-center justify-center shrink-0 mt-0.5">
                  <Icon size={16} className="text-indigo-400" />
                </div>
                <div>
                  <p className={`font-semibold text-sm mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>{title}</p>
                  <p className={`text-xs leading-relaxed ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>{desc}</p>
                </div>
              </TiltCard>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}

// ── How It Works ──────────────────────────────────────────────────────────────
function HowItWorksSection() {
  const { isDark } = useTheme();
  return (
    <section id="how-it-works" className={`py-28 px-6 ${isDark ? 'bg-gray-900/30' : 'bg-gray-100/60'}`}>
      <div className="max-w-5xl mx-auto">
        <FadeIn className="text-center mb-16">
          <span className="text-emerald-400 text-sm font-semibold tracking-widest uppercase">Workflow</span>
          <h2 className={`text-4xl md:text-5xl font-black mt-3 mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            From setup to insight in minutes
          </h2>
          <p className={`max-w-xl mx-auto ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            No IT deployment, no cloud keys, no configuration hell. Open the app and go.
          </p>
        </FadeIn>

        <div className="relative">
          {/* Connecting line */}
          <div className={`hidden md:block absolute left-1/2 top-8 bottom-8 w-px ${isDark ? 'bg-white/5' : 'bg-gray-200'}`} />

          <div className="space-y-12">
            {HOW_IT_WORKS.map((step, i) => (
              <FadeIn key={step.step} delay={i * 0.15}>
                <div className={`flex flex-col ${i % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'} gap-8 items-center`}>
                  <div className="md:flex-1 md:text-right">
                    {i % 2 === 0 ? (
                      <>
                        <span className={`inline-flex items-center gap-2 text-xs font-semibold px-3 py-1 rounded-full bg-gradient-to-r ${step.color} text-white mb-3`}>
                          {step.role}
                        </span>
                        <h3 className={`text-xl font-bold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>{step.title}</h3>
                        <p className={`leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{step.desc}</p>
                      </>
                    ) : <div />}
                  </div>

                  <motion.div whileHover={{ scale: 1.08 }}
                    className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${step.color} flex items-center justify-center shrink-0 text-white font-black text-xl shadow-lg z-10`}>
                    {step.step}
                  </motion.div>

                  <div className="md:flex-1">
                    {i % 2 !== 0 ? (
                      <>
                        <span className={`inline-flex items-center gap-2 text-xs font-semibold px-3 py-1 rounded-full bg-gradient-to-r ${step.color} text-white mb-3`}>
                          {step.role}
                        </span>
                        <h3 className={`text-xl font-bold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>{step.title}</h3>
                        <p className={`leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{step.desc}</p>
                      </>
                    ) : <div />}
                  </div>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

// ── Tech Stack ────────────────────────────────────────────────────────────────
function TechStackSection() {
  const { isDark } = useTheme();
  return (
    <section id="tech" className="py-28 px-6">
      <div className="max-w-6xl mx-auto">
        <FadeIn className="text-center mb-16">
          <span className="text-violet-400 text-sm font-semibold tracking-widest uppercase">Built With</span>
          <h2 className={`text-4xl md:text-5xl font-black mt-3 mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            Production-grade. No shortcuts.
          </h2>
          <p className={`max-w-xl mx-auto ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            Every library chosen for a reason — not just to pad a résumé.
          </p>
        </FadeIn>

        <div className="grid md:grid-cols-3 gap-6 mb-10">
          {TECH_STACK.map(({ category, icon: Icon, color, items }, i) => (
            <FadeIn key={category} delay={i * 0.1}>
              <TiltCard className={`border rounded-2xl p-6 transition h-full cursor-default ${
                isDark ? 'bg-gray-900/60 border-white/5 hover:border-white/10' : 'bg-white border-gray-200 hover:border-gray-300'
              }`}>
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${color} flex items-center justify-center mb-5 shadow-md`}>
                  <Icon size={22} className="text-white" />
                </div>
                <h3 className={`font-bold text-lg mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>{category}</h3>
                <ul className="space-y-2.5">
                  {items.map(item => (
                    <li key={item} className={`flex items-center gap-2.5 text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                      <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 shrink-0" />{item}
                    </li>
                  ))}
                </ul>
              </TiltCard>
            </FadeIn>
          ))}
        </div>

        {/* Architecture diagram — accurate, no backend */}
        <FadeIn>
          <div className={`border rounded-2xl p-8 ${isDark ? 'bg-gray-900/60 border-white/5' : 'bg-white border-gray-200'}`}>
            <h3 className={`text-sm font-semibold text-center mb-8 uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
              Architecture — everything on the device
            </h3>
            <div className="flex flex-col md:flex-row items-center justify-center gap-4 text-sm flex-wrap">
              {[
                { label: 'Flutter App', sub: 'Dart · Material 3', bg: 'bg-blue-500/15 border-blue-500/30 text-blue-400' },
                { arrow: true },
                { label: 'Drift ORM', sub: 'SQLite on-device', bg: 'bg-violet-500/15 border-violet-500/30 text-violet-400' },
                { arrow: true },
                { label: 'ML Kit + LBP', sub: 'Face AI on-device', bg: 'bg-emerald-500/15 border-emerald-500/30 text-emerald-400' },
              ].map((item, i) =>
                'arrow' in item
                  ? <ArrowRight key={i} size={18} className={`rotate-90 md:rotate-0 ${isDark ? 'text-gray-600' : 'text-gray-400'}`} />
                  : <div key={i} className={`px-5 py-3 rounded-xl border ${item.bg} text-center min-w-[150px]`}>
                      <div className="font-semibold">{item.label}</div>
                      <div className="text-xs opacity-60 mt-0.5">{item.sub}</div>
                    </div>
              )}
            </div>
            <p className={`text-center text-xs mt-6 ${isDark ? 'text-gray-600' : 'text-gray-400'}`}>
              No backend · No cloud · No internet · All data stays on-device
            </p>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

// ── Portfolio / CTA ───────────────────────────────────────────────────────────
function PortfolioSection() {
  const { isDark } = useTheme();
  return (
    <section className={`py-20 px-6 ${isDark ? 'bg-gray-900/30' : 'bg-gray-100/60'}`}>
      <div className="max-w-4xl mx-auto">
        <FadeIn>
          <div className={`relative overflow-hidden border rounded-3xl p-10 text-center ${
            isDark ? 'bg-gray-900/80 border-white/8' : 'bg-white border-gray-200'
          }`}>
            {/* Background glow */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-96 h-32 bg-indigo-600/15 blur-3xl rounded-full" />

            <div className="relative">
              <div className="flex justify-center gap-1 mb-5">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} size={18} className="text-amber-400 fill-amber-400" />
                ))}
              </div>
              <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1 rounded-full border mb-5 ${
                isDark ? 'bg-indigo-500/10 border-indigo-500/20 text-indigo-400' : 'bg-indigo-50 border-indigo-200 text-indigo-600'
              }`}>
                <Code2 size={12} /> Portfolio Project
              </span>
              <h2 className={`text-3xl md:text-4xl font-black mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>
                Built to demonstrate real-world skills
              </h2>
              <p className={`max-w-2xl mx-auto mb-8 leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                AdaptAttend is a full-stack mobile portfolio project — offline-first architecture, on-device biometrics, type-safe SQLite ORM, and a polished Material 3 UI. Every component is production-ready, not toy code.
              </p>
              <div className="flex flex-wrap gap-3 justify-center">
                <a href="https://github.com/itsmittalharshit/adaptattend" target="_blank" rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-6 py-3 rounded-xl font-semibold transition shadow-lg shadow-indigo-600/20">
                  <Github size={17} /> View on GitHub <ExternalLink size={13} className="opacity-60" />
                </a>
                <a href="https://www.linkedin.com/in/theharshitmittal/" target="_blank" rel="noopener noreferrer"
                  className={`inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition border ${
                    isDark ? 'border-white/10 hover:border-white/20 text-gray-300 hover:text-white' : 'border-gray-300 hover:border-gray-400 text-gray-600 hover:text-gray-900'
                  }`}>
                  <Linkedin size={17} /> LinkedIn <ExternalLink size={13} className="opacity-40" />
                </a>
              </div>
            </div>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

// ── Contact ───────────────────────────────────────────────────────────────────
function ContactSection() {
  const { isDark } = useTheme();
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');
  const [form, setForm] = useState({ name: '', email: '', subject: '', message: '' });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('sending');
    try {
      const body = `Hi Harshit,\n\nName: ${form.name}\nEmail: ${form.email}\n\n${form.message}`;
      window.open(`mailto:mittalharshit99@gmail.com?subject=${encodeURIComponent(form.subject)}&body=${encodeURIComponent(body)}`, '_self');
      await new Promise(r => setTimeout(r, 400));
      setStatus('sent');
      setForm({ name: '', email: '', subject: '', message: '' });
    } catch {
      setStatus('error');
    }
  };

  const inputCls = `w-full border rounded-xl px-4 py-3 text-sm focus:outline-none transition ${
    isDark
      ? 'bg-gray-800/80 border-white/5 text-white placeholder-gray-600 focus:border-indigo-500/50 focus:bg-gray-800'
      : 'bg-gray-50 border-gray-200 text-gray-900 placeholder-gray-400 focus:border-indigo-400 focus:bg-white'
  }`;

  const CONTACT_LINKS = [
    { href: 'https://github.com/itsmittalharshit',              icon: Github,   label: 'GitHub' },
    { href: 'https://www.linkedin.com/in/theharshitmittal/',     icon: Linkedin, label: 'LinkedIn' },
    { href: 'mailto:mittalharshit99@gmail.com',                  icon: Mail,     label: 'Email' },
  ];

  return (
    <section id="contact" className="py-28 px-6">
      <div className="max-w-5xl mx-auto">
        <FadeIn className="text-center mb-16">
          <span className="text-cyan-400 text-sm font-semibold tracking-widest uppercase">Get In Touch</span>
          <h2 className={`text-4xl md:text-5xl font-black mt-3 mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            Want to know more?
          </h2>
          <p className={`max-w-xl mx-auto ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            Collaboration idea, technical deep-dive, or just want to connect — I&apos;m all ears.
          </p>
        </FadeIn>

        <div className="grid md:grid-cols-2 gap-12 items-start">
          <FadeIn className="space-y-8">
            <div>
              <h3 className={`font-bold text-lg mb-3 ${isDark ? 'text-white' : 'text-gray-900'}`}>What I built this for</h3>
              <p className={`leading-relaxed ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
                A portfolio project showcasing real-world mobile system design — offline-first architecture, on-device biometrics, type-safe SQLite via Drift ORM, and a clean Material 3 UI with dark/light theming.
              </p>
            </div>
            <div className="space-y-4">
              {[
                { icon: Smartphone, label: 'Offline-first Flutter app',   desc: 'Drift ORM + SQLite — every feature works with zero internet' },
                { icon: Fingerprint, label: 'On-device face recognition', desc: 'LBP + Google ML Kit — no server, no cloud upload' },
                { icon: BarChart3,   label: 'Rich analytics dashboard',   desc: 'Daily heatmaps, punctuality scores, method breakdowns' },
              ].map(({ icon: Icon, label, desc }) => (
                <div key={label} className="flex gap-4">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                    isDark ? 'bg-indigo-500/10 border border-indigo-500/20' : 'bg-indigo-50 border border-indigo-200'
                  }`}>
                    <Icon size={17} className="text-indigo-400" />
                  </div>
                  <div>
                    <p className={`font-medium text-sm ${isDark ? 'text-white' : 'text-gray-900'}`}>{label}</p>
                    <p className={`text-xs mt-0.5 ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>{desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="flex gap-3 flex-wrap">
              {CONTACT_LINKS.map(({ href, icon: Icon, label }) => (
                <a key={label} href={href}
                  target={href.startsWith('http') ? '_blank' : undefined}
                  rel="noopener noreferrer"
                  className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm transition border ${
                    isDark
                      ? 'bg-gray-800 hover:bg-gray-700 text-gray-300 hover:text-white border-white/5'
                      : 'bg-white hover:bg-gray-50 text-gray-600 hover:text-gray-900 border-gray-200'
                  }`}>
                  <Icon size={15} /> {label}
                </a>
              ))}
            </div>
          </FadeIn>

          <FadeIn delay={0.1}>
            <form onSubmit={handleSubmit}
              className={`border rounded-2xl p-7 space-y-4 ${isDark ? 'bg-gray-900/60 border-white/5' : 'bg-white border-gray-200'}`}>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className={`block text-xs mb-1.5 font-medium ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>Name</label>
                  <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required placeholder="Your name" className={inputCls} />
                </div>
                <div>
                  <label className={`block text-xs mb-1.5 font-medium ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>Email</label>
                  <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required placeholder="your@email.com" className={inputCls} />
                </div>
              </div>
              <div>
                <label className={`block text-xs mb-1.5 font-medium ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>Subject</label>
                <input value={form.subject} onChange={e => setForm({ ...form, subject: e.target.value })} required placeholder="What's this about?" className={inputCls} />
              </div>
              <div>
                <label className={`block text-xs mb-1.5 font-medium ${isDark ? 'text-gray-500' : 'text-gray-500'}`}>Message</label>
                <textarea value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} required rows={5}
                  placeholder="Tell me what you're thinking…" className={`${inputCls} resize-none`} />
              </div>
              <button type="submit" disabled={status === 'sending' || status === 'sent'}
                className="w-full bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white py-3.5 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 transition shadow-md shadow-indigo-600/15">
                {status === 'sending'
                  ? <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  : status === 'sent'
                    ? <><CheckCircle2 size={16} /> Message sent!</>
                    : <><Send size={15} /> Send Message</>}
              </button>
              {status === 'error' && <p className="text-red-400 text-xs text-center">Something went wrong — email mittalharshit99@gmail.com directly.</p>}
              {status === 'sent' && <p className="text-emerald-400 text-xs text-center">Thanks! I&apos;ll reply as soon as I can.</p>}
            </form>
          </FadeIn>
        </div>
      </div>
    </section>
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────
function Footer() {
  const { isDark } = useTheme();
  return (
    <footer className={`border-t py-10 px-6 ${isDark ? 'border-white/5' : 'border-gray-200'}`}>
      <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-2 font-bold">
          <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center">
            <ScanFace size={14} className="text-white" />
          </div>
          <span className={isDark ? 'text-gray-300' : 'text-gray-700'}>AdaptAttend</span>
        </div>
        <div className="flex flex-wrap justify-center gap-6 text-sm">
          {NAV_LINKS.map(l => (
            <a key={l.label} href={l.href}
              className={`transition ${isDark ? 'text-gray-600 hover:text-gray-400' : 'text-gray-400 hover:text-gray-600'}`}>
              {l.label}
            </a>
          ))}
        </div>
        <div className="flex items-center gap-4">
          <a href="https://github.com/itsmittalharshit" target="_blank" rel="noopener noreferrer"
            className={`transition ${isDark ? 'text-gray-600 hover:text-gray-400' : 'text-gray-400 hover:text-gray-600'}`}>
            <Github size={18} />
          </a>
          <a href="https://www.linkedin.com/in/theharshitmittal/" target="_blank" rel="noopener noreferrer"
            className={`transition ${isDark ? 'text-gray-600 hover:text-gray-400' : 'text-gray-400 hover:text-gray-600'}`}>
            <Linkedin size={18} />
          </a>
          <a href="mailto:mittalharshit99@gmail.com"
            className={`transition ${isDark ? 'text-gray-600 hover:text-gray-400' : 'text-gray-400 hover:text-gray-600'}`}>
            <Mail size={18} />
          </a>
        </div>
      </div>
      <div className={`text-center text-xs mt-6 ${isDark ? 'text-gray-700' : 'text-gray-400'}`}>
        Built by <a href="https://www.linkedin.com/in/theharshitmittal/" target="_blank" rel="noopener noreferrer"
          className="hover:text-indigo-400 transition">Harshit Mittal</a>
        &nbsp;· Flutter · Drift · ML Kit · Zero servers
      </div>
    </footer>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────
export default function HomePage() {
  const [isDark, setIsDark] = useState(true);
  return (
    <ThemeCtx.Provider value={{ isDark, toggle: () => setIsDark(d => !d) }}>
      <main className={`min-h-screen antialiased transition-colors duration-300 ${isDark ? 'bg-gray-950 text-white' : 'bg-slate-50 text-gray-900'}`}>
        <Navbar />
        <HeroSection />
        <TechTicker />
        <StatsSection />
        <FeaturesSection />
        <HowItWorksSection />
        <TechStackSection />
        <PortfolioSection />
        <ContactSection />
        <Footer />
      </main>
    </ThemeCtx.Provider>
  );
}
