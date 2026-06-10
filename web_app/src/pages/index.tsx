import { useEffect, useRef, useState, FormEvent } from 'react';
import Link from 'next/link';
import Head from 'next/head';
import styles from './landing.module.css';

// Landing-only static deploy (NEXT_PUBLIC_LANDING_ONLY=1): the web-app routes
// are not hosted, so "Open Web App" CTAs point at the download section and the
// contact form posts straight to the backend (NEXT_PUBLIC_API_BASE) instead of
// the dev proxy. Both are baked in at build time.
const LANDING_ONLY = process.env.NEXT_PUBLIC_LANDING_ONLY === '1';
const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';
const WEB_LOGIN = LANDING_ONLY ? '#download' : '/login';
const WEB_REGISTER = LANDING_ONLY ? '#download' : '/register';
const ANDROID_APK_URL = '/ClickerPro.apk';

const FEATURES = [
  { icon: '📅', name: 'Smart Booking Management', desc: 'Handle every event from inquiry to delivery. Track status, assign team, manage timelines effortlessly.' },
  { icon: '💳', name: 'Invoicing & Payments', desc: 'Generate professional invoices, track payments via bKash, Nagad, bank transfer, and cash.' },
  { icon: '👥', name: 'Client CRM', desc: 'Build long-lasting client relationships with full history, notes, and communication logs.' },
  { icon: '📷', name: 'Gear & Equipment', desc: 'Catalogue your camera bodies, lenses, lights, and accessories. Track availability and condition.' },
  { icon: '📈', name: 'Revenue Reports', desc: 'See monthly revenue trends, outstanding payments, and business growth at a glance.' },
  { icon: '👤', name: 'Team Coordination', desc: 'Assign team members to shoots, manage roles, and keep everyone on the same page.' },
];

const HOW_IT_WORKS = [
  { step: '01', title: 'Create Your Account', desc: 'Sign up free in under a minute. Set up your business profile, logo, and team — no credit card required.' },
  { step: '02', title: 'Add Bookings & Clients', desc: 'Log every event with date, shift, package, and payment. Your client list and calendar build themselves.' },
  { step: '03', title: 'Track Money & Delivery', desc: 'Record advances and dues, generate invoices, and keep tabs on editing and delivery status in one place.' },
  { step: '04', title: 'Grow With Insights', desc: 'Watch revenue trends, outstanding dues, and team performance — and make smarter decisions every month.' },
];

const TESTIMONIALS = [
  { name: 'Rafiul Islam', role: 'Wedding Photographer, Dhaka', quote: 'ClickerPro replaced three different apps I used to juggle. Now bookings, payments, and my team are all in one screen. Game changer.', avatar: 'RI' },
  { name: 'Tahmina Akter', role: 'Studio Owner, Chattogram', quote: 'The due-tracking alone paid for itself in the first month. I stopped losing money to forgotten payments. Highly recommend.', avatar: 'TA' },
  { name: 'Sabbir Hossain', role: 'Freelance Cinematographer', quote: 'As a freelancer I can finally see exactly who owes me what across every studio I work with. The earnings view is brilliant.', avatar: 'SH' },
];

const FAQS = [
  { q: 'Is ClickerPro free to start?', a: 'Yes. The Starter plan is free forever and includes core booking and client management. Upgrade only when you need unlimited bookings and advanced features.' },
  { q: 'Does it work on mobile and laptop?', a: 'Absolutely. ClickerPro runs as a web app on any laptop or desktop, plus native mobile apps for Android and iOS — all synced in real time.' },
  { q: 'Can I track bKash and Nagad payments?', a: 'Yes. Record payments by cash, bKash, Nagad, bank transfer, or card. Every advance and due is tracked automatically per booking.' },
  { q: 'Can my team use it together?', a: 'Yes. Invite team members, assign them to shoots, set role-based permissions, and manage payouts — all from the Team section.' },
  { q: 'Is my data safe?', a: 'Your data is stored securely with regular backups. You can export everything to CSV anytime, and optional two-factor authentication protects your account.' },
];

const PRICING = [
  {
    name: 'Starter',
    price: '0',
    period: 'Free forever',
    badge: null,
    featured: false,
    features: ['5 bookings/month', '1 team member', 'Basic invoicing', 'Client CRM', 'Mobile app access'],
  },
  {
    name: 'Pro',
    price: '999',
    period: 'per month',
    badge: 'Most Popular',
    featured: true,
    features: ['Unlimited bookings', '5 team members', 'Advanced invoicing', 'Payment tracking', 'Revenue reports', 'Gear management', 'Priority support'],
  },
  {
    name: 'Business',
    price: '2499',
    period: 'per month',
    badge: null,
    featured: false,
    features: ['Everything in Pro', 'Unlimited team members', 'Multi-branch support', 'Custom branding', 'API access', 'Dedicated support'],
  },
];

export default function LandingPage() {
  const cursorRef = useRef<HTMLDivElement>(null);
  const cursorRingRef = useRef<HTMLDivElement>(null);
  const navRef = useRef<HTMLElement>(null);

  // Contact form
  const [contact, setContact] = useState({ name: '', email: '', message: '' });
  const [contactState, setContactState] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const submitContact = async (e: FormEvent) => {
    e.preventDefault();
    if (!contact.name || !contact.email || !contact.message) return;
    setContactState('sending');
    try {
      const res = await fetch(`${API_BASE}/api/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(contact),
      });
      if (!res.ok) throw new Error();
      setContactState('sent');
      setContact({ name: '', email: '', message: '' });
    } catch {
      setContactState('error');
    }
  };

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (cursorRef.current) {
        cursorRef.current.style.left = e.clientX + 'px';
        cursorRef.current.style.top = e.clientY + 'px';
      }
      if (cursorRingRef.current) {
        cursorRingRef.current.style.left = e.clientX + 'px';
        cursorRingRef.current.style.top = e.clientY + 'px';
      }
    };
    window.addEventListener('mousemove', onMove);
    return () => window.removeEventListener('mousemove', onMove);
  }, []);

  useEffect(() => {
    const onScroll = () => {
      if (navRef.current) {
        if (window.scrollY > 50) navRef.current.classList.add(styles.scrolled);
        else navRef.current.classList.remove(styles.scrolled);
      }
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    let destroyed = false;

    const initGsap = async () => {
      try {
        const { default: gsap } = await import('gsap');
        const { ScrollTrigger } = await import('gsap/ScrollTrigger');
        if (destroyed) return;

        gsap.registerPlugin(ScrollTrigger);

        const container = document.querySelector<HTMLElement>(`.${styles.bladeContainer}`);
        if (container) {
          container.innerHTML = '';
          const numBlades = 42;
          const isWide = window.innerWidth > 768;
          for (let i = 0; i < numBlades; i++) {
            const blade = document.createElement('div');
            blade.className = 'cp-blade';
            blade.style.position = 'absolute';
            blade.style.top = '50%';
            blade.style.right = '0';
            blade.style.transformOrigin = 'right center';
            blade.style.width = isWide ? '65vw' : '90vw';
            blade.style.height = '5.5vw';
            blade.style.minHeight = '32px';
            blade.style.borderRadius = '100% 0 0 100% / 50% 0 0 50%';
            const progress = i / (numBlades - 1);
            const angle = -85 + progress * 170;
            blade.style.transform = `translateY(-50%) rotate(${angle}deg)`;
            blade.style.zIndex = String(i);
            blade.style.opacity = '0';
            blade.style.background =
              'linear-gradient(to bottom, rgba(255,255,255,0.45) 0%, rgba(255,255,255,0) 8%, rgba(0,0,0,0) 85%, rgba(0,0,0,0.8) 100%),' +
              'linear-gradient(to right, #ffedcc 0%, #ff6200 15%, #a11b00 45%, #1f0400 80%, #050100 100%)';
            blade.style.boxShadow =
              '0px 18px 45px -8px rgba(0,0,0,0.95), inset 0px 2px 4px rgba(255,255,255,0.4), inset 0px -4px 12px rgba(0,0,0,0.9)';
            container.appendChild(blade);
          }

          const blades = gsap.utils.toArray<HTMLElement>('.cp-blade');

          // 1. Unfurling reveal from center
          gsap.to(blades, {
            opacity: 1,
            duration: 2.5,
            stagger: { amount: 1.8, from: 'center' },
            ease: 'power2.out',
            delay: 0.2,
          });

          // 2. Ambient breathing of the whole hub
          gsap.to(container, {
            rotation: -4,
            duration: 16,
            repeat: -1,
            yoyo: true,
            ease: 'sine.inOut',
          });

          // 3. Organic per-blade flex
          blades.forEach((blade, index) => {
            gsap.to(blade, {
              rotation: `+=${2 + (index % 2.5)}`,
              scaleX: 1.015 + (index % 3) * 0.005,
              duration: 5 + (index % 3),
              repeat: -1,
              yoyo: true,
              ease: 'sine.inOut',
              delay: index * 0.06,
            });
          });

          // 4. Subtle scroll parallax
          ScrollTrigger.create({
            trigger: '.js-hero',
            start: 'top top',
            end: 'bottom top',
            onUpdate: (self) => {
              gsap.to(container, { x: self.progress * 60, duration: 0.3, overwrite: 'auto' });
            },
          });

          const onResize = () => {
            const w = window.innerWidth > 768 ? '65vw' : '90vw';
            blades.forEach((b) => { b.style.width = w; });
          };
          window.addEventListener('resize', onResize);
        }

        gsap.to(`.${styles.eyebrowSpan}`, { y: 0, duration: 0.9, delay: 0.3, ease: 'power3.out' });
        gsap.to(`.${styles.titleLine}`, { y: 0, duration: 1, stagger: 0.1, delay: 0.5, ease: 'power4.out' });
        gsap.to(`.${styles.heroDesc}`, { opacity: 1, y: 0, duration: 0.9, delay: 0.9, ease: 'power2.out' });
        gsap.to(`.${styles.heroActions}`, { opacity: 1, y: 0, duration: 0.9, delay: 1.1, ease: 'power2.out' });
        gsap.to(`.${styles.heroStats}`, { opacity: 1, duration: 0.9, delay: 1.3, ease: 'power2.out' });
        gsap.to(`.${styles.scrollLine}`, { opacity: 1, duration: 0.9, delay: 1.5, ease: 'power2.out' });
      } catch {
        // GSAP unavailable — show content without animation
        const els = document.querySelectorAll<HTMLElement>(
          `.${styles.heroDesc},.${styles.heroActions},.${styles.heroStats},.${styles.scrollLine},.${styles.eyebrowSpan},.${styles.titleLine}`
        );
        els.forEach((el) => { el.style.opacity = '1'; el.style.transform = 'none'; });
      }
    };

    initGsap();
    return () => { destroyed = true; };
  }, []);

  return (
    <>
      <Head>
        <title>ClickerPro — Management for Photographers</title>
        <meta name="description" content="All-in-one management platform for photographers and videographers. Bookings, invoices, clients, team — all in one place." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>

      <div ref={cursorRef} className={styles.cursor} />
      <div ref={cursorRingRef} className={styles.cursorRing} />
      <canvas className={styles.grain} />

      <nav ref={navRef} className={styles.nav}>
        <div className={styles.navLogo}>Clicker<span>Pro</span></div>
        <div className={styles.navLinks}>
          <a href="#features">Features</a>
          <a href="#how">How It Works</a>
          <a href="#pricing">Pricing</a>
          <a href="#faq">FAQ</a>
          <a href="#contact">Contact</a>
          <Link href={WEB_LOGIN} className={styles.navCta}>
            {LANDING_ONLY ? 'Get the App →' : 'Launch Web App →'}
          </Link>
        </div>
      </nav>

      {/* Hero */}
      <section className={`${styles.hero} js-hero`}>
        <div className={styles.heroBg} />
        <div className={styles.heroBgGlow} />
        <div className={styles.bladeContainer} />

        <div className={styles.heroContent}>
          <div className={styles.heroEyebrow}>
            <span className={styles.eyebrowSpan}>— Professional Photography Management</span>
          </div>
          <h1 className={styles.heroTitle}>
            <span className={styles.titleMask}><span className={styles.titleLine}>Run Your</span></span>
            <span className={styles.titleMask}><span className={`${styles.titleLine} ${styles.titleOrange}`}>Photography</span></span>
            <span className={styles.titleMask}><span className={styles.titleLine}>Business.</span></span>
          </h1>
          <p className={styles.heroDesc}>
            ClickerPro is the all-in-one management platform built for photographers and videographers.
            Bookings, invoices, clients, and team — all in one place.
          </p>
          <div className={styles.heroActions}>
            <Link href={WEB_LOGIN} className={styles.btnPrimary}>
              {LANDING_ONLY ? 'Download the App →' : 'Open Web App →'}
            </Link>
            <a href="#features" className={styles.btnSecondary}>Explore Features</a>
          </div>
        </div>

        <div className={styles.heroStats}>
          <div>
            <div className={styles.statNum}>2,400+</div>
            <div className={styles.statLabel}>Active Users</div>
          </div>
          <div>
            <div className={styles.statNum}>48K+</div>
            <div className={styles.statLabel}>Bookings Managed</div>
          </div>
          <div>
            <div className={styles.statNum}>৳ 12Cr</div>
            <div className={styles.statLabel}>Revenue Tracked</div>
          </div>
        </div>

        <div className={styles.scrollLine}>
          <div className={styles.scrollBar} />
          <span className={styles.scrollLabel}>Scroll</span>
        </div>
      </section>

      {/* Features */}
      <section id="features" className={`${styles.featuresSection} ${styles.sectionPad}`}>
        <div className={styles.sectionEyebrow}>Everything You Need</div>
        <h2 className={styles.sectionTitle}>Built For<br />Creative Pros</h2>
        <p className={styles.sectionDesc}>Every tool your photography business needs, carefully designed for the way you work.</p>
        <div className={styles.featuresGrid}>
          {FEATURES.map((f, i) => (
            <div key={f.name} className={styles.featureCard}>
              <div className={styles.featureNum}>0{i + 1}</div>
              <div className={styles.featureIcon}>{f.icon}</div>
              <div className={styles.featureName}>{f.name}</div>
              <p className={styles.featureDesc}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* App Preview */}
      <section id="preview" className={`${styles.previewSection} ${styles.sectionPad}`}>
        <div className={styles.previewInner}>
          <div>
            <div className={styles.sectionEyebrow}>App Preview</div>
            <h2 className={styles.sectionTitle}>Designed For<br />Your Workflow</h2>
            <div className={styles.featureList}>
              {[
                { title: 'Instant overview', desc: "See today's bookings, pending payments, and revenue at a glance on your dashboard." },
                { title: 'One-tap booking', desc: 'Create a new booking in under 30 seconds. Assign team, set venue, and go.' },
                { title: 'Real-time sync', desc: 'All your data syncs instantly across web and mobile.' },
                { title: 'Offline support', desc: 'Keep working even without internet. Sync when reconnected.' },
              ].map((item) => (
                <div key={item.title} className={styles.flItem}>
                  <div className={styles.flDot} />
                  <p className={styles.flText}><strong>{item.title}.</strong> {item.desc}</p>
                </div>
              ))}
            </div>
          </div>

          <div className={styles.phoneMockup}>
            <div className={styles.phoneFrame}>
              <div className={styles.phoneScreen}>
                <div className={styles.phoneScreenInner}>
                  <div className={styles.psHeader}>
                    <div className={styles.psLogo}>Clicker<span>Pro</span></div>
                    <div className={styles.psAvatar}>RK</div>
                  </div>
                  <div className={styles.psGreeting}>
                    Good morning,<strong>Rafi Khan</strong>
                  </div>
                  <div className={styles.psTiles}>
                    {[
                      { icon: '📅', label: "Today's Shoots", val: '3' },
                      { icon: '💰', label: 'This Month', val: '৳84K' },
                      { icon: '⏳', label: 'Pending', val: '৳22K' },
                      { icon: '👥', label: 'Clients', val: '142' },
                    ].map((t) => (
                      <div key={t.label} className={styles.psTile}>
                        <div className={styles.psTileIcon}>{t.icon}</div>
                        <div className={styles.psTileLabel}>{t.label}</div>
                        <div className={styles.psTileVal}>{t.val}</div>
                      </div>
                    ))}
                  </div>
                  <div className={styles.psRecent}>
                    <div className={styles.psRecentLabel}>Recent Bookings</div>
                    {[
                      { name: 'Nadia & Karim Wedding', time: 'Today, 9:00 AM', amt: '৳45,000', color: '#22c55e' },
                      { name: 'Corporate Annual Day', time: 'Tomorrow, 10:00 AM', amt: '৳18,000', color: '#d6a84c' },
                      { name: 'Rahman Baby Shower', time: 'Dec 20, 2:00 PM', amt: '৳12,000', color: '#14b8a6' },
                    ].map((b) => (
                      <div key={b.name} className={styles.psBooking}>
                        <div className={styles.psBookingDot} style={{ background: b.color }} />
                        <div className={styles.psBookingInfo}>
                          <div className={styles.psBookingName}>{b.name}</div>
                          <div className={styles.psBookingTime}>{b.time}</div>
                        </div>
                        <div className={styles.psBookingAmt}>{b.amt}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <div className={styles.phoneGlow} />
          </div>
        </div>
      </section>

      {/* Download */}
      <section id="download" className={`${styles.downloadSection} ${styles.sectionPad}`}>
        <div className={styles.downloadInner}>
          <div>
            <div className={styles.sectionEyebrow}>Available Everywhere</div>
            <h2 className={styles.sectionTitle}>Web &amp; Mobile<br />Apps Included</h2>
            <div className={styles.downloadBadges}>
              <a href="#" className={styles.storeBadge}>
                <span>🍎</span>
                <div>
                  <div className={styles.badgeSub}>Download on the</div>
                  <div className={styles.badgeName}>App Store</div>
                </div>
              </a>
              <a
                href={LANDING_ONLY ? ANDROID_APK_URL : '#'}
                {...(LANDING_ONLY ? { download: true } : {})}
                className={styles.storeBadge}
              >
                <span>▶</span>
                <div>
                  <div className={styles.badgeSub}>
                    {LANDING_ONLY ? 'Android' : 'Get it on'}
                  </div>
                  <div className={styles.badgeName}>
                    {LANDING_ONLY ? 'Download APK' : 'Google Play'}
                  </div>
                </div>
              </a>
            </div>
          </div>
          <div className={styles.downloadChecks}>
            {[
              'Works on iPhone, iPad, Android, and Web',
              'Real-time sync across all your devices',
              'Offline mode — works without internet',
              'Bengali and English language support',
              'Dark mode optimized interface',
            ].map((item) => (
              <div key={item} className={styles.checkItem}>
                <span style={{ color: '#FF6200', fontWeight: 700 }}>✓</span>
                {item}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className={`${styles.pricingSection} ${styles.sectionPad}`}>
        <div style={{ textAlign: 'center' }}>
          <div className={styles.sectionEyebrow}>Pricing</div>
          <h2 className={styles.sectionTitle}>Simple, Honest<br />Pricing</h2>
        </div>
        <div className={styles.pricingGrid}>
          {PRICING.map((plan) => (
            <div key={plan.name} className={`${styles.priceCard} ${plan.featured ? styles.featured : ''}`}>
              {plan.badge && <div className={styles.priceBadge}>{plan.badge}</div>}
              <div className={styles.priceName}>{plan.name}</div>
              <div className={styles.priceAmount}><sup>৳</sup>{plan.price}</div>
              <div className={styles.pricePeriod}>{plan.period}</div>
              <ul className={styles.priceFeatures}>
                {plan.features.map((f) => <li key={f}>{f}</li>)}
              </ul>
              <Link href={WEB_REGISTER} className={styles.btnPrimary} style={{ width: '100%', justifyContent: 'center' }}>
                {plan.name === 'Starter' ? 'Start Free' : 'Start Free Trial'}
              </Link>
            </div>
          ))}
        </div>
      </section>

      {/* How It Works */}
      <section id="how" className={`${styles.howSection} ${styles.sectionPad}`}>
        <div style={{ textAlign: 'center' }}>
          <div className={styles.sectionEyebrow}>How It Works</div>
          <h2 className={styles.sectionTitle}>Up &amp; Running<br />In Minutes</h2>
        </div>
        <div className={styles.stepsGrid}>
          {HOW_IT_WORKS.map((s) => (
            <div key={s.step} className={styles.stepCard}>
              <div className={styles.stepNum}>{s.step}</div>
              <div className={styles.stepTitle}>{s.title}</div>
              <p className={styles.stepDesc}>{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className={`${styles.testimonialsSection} ${styles.sectionPad}`}>
        <div style={{ textAlign: 'center' }}>
          <div className={styles.sectionEyebrow}>Loved By Creators</div>
          <h2 className={styles.sectionTitle}>What Our Users<br />Are Saying</h2>
        </div>
        <div className={styles.testimonialGrid}>
          {TESTIMONIALS.map((t) => (
            <div key={t.name} className={styles.testimonialCard}>
              <p className={styles.testimonialQuote}>&ldquo;{t.quote}&rdquo;</p>
              <div className={styles.testimonialAuthor}>
                <div className={styles.testimonialAvatar}>{t.avatar}</div>
                <div>
                  <div className={styles.testimonialName}>{t.name}</div>
                  <div className={styles.testimonialRole}>{t.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className={`${styles.faqSection} ${styles.sectionPad}`}>
        <div style={{ textAlign: 'center' }}>
          <div className={styles.sectionEyebrow}>FAQ</div>
          <h2 className={styles.sectionTitle}>Questions?<br />Answered.</h2>
        </div>
        <div className={styles.faqList}>
          {FAQS.map((f) => (
            <details key={f.q} className={styles.faqItem}>
              <summary className={styles.faqQ}>{f.q}</summary>
              <p className={styles.faqA}>{f.a}</p>
            </details>
          ))}
        </div>
      </section>

      {/* Contact */}
      <section id="contact" className={`${styles.contactSection} ${styles.sectionPad}`}>
        <div style={{ textAlign: 'center' }}>
          <div className={styles.sectionEyebrow}>Get In Touch</div>
          <h2 className={styles.sectionTitle}>Have a Question?<br />Talk to Us.</h2>
        </div>
        <form className={styles.contactForm} onSubmit={submitContact}>
          {contactState === 'sent' ? (
            <div className={styles.contactSuccess}>
              ✓ Thanks! We received your message and will get back to you soon.
            </div>
          ) : (
            <>
              <div className={styles.contactRow}>
                <input
                  className={styles.contactInput}
                  placeholder="Your name"
                  value={contact.name}
                  onChange={(e) => setContact({ ...contact, name: e.target.value })}
                  required
                />
                <input
                  className={styles.contactInput}
                  type="email"
                  placeholder="Your email"
                  value={contact.email}
                  onChange={(e) => setContact({ ...contact, email: e.target.value })}
                  required
                />
              </div>
              <textarea
                className={styles.contactTextarea}
                placeholder="How can we help?"
                rows={5}
                value={contact.message}
                onChange={(e) => setContact({ ...contact, message: e.target.value })}
                required
              />
              {contactState === 'error' && (
                <div className={styles.contactError}>Something went wrong. Please try again.</div>
              )}
              <button type="submit" className={styles.btnPrimary} disabled={contactState === 'sending'} style={{ alignSelf: 'flex-start' }}>
                {contactState === 'sending' ? 'Sending…' : 'Send Message →'}
              </button>
            </>
          )}
        </form>
      </section>

      {/* CTA band */}
      <section className={styles.ctaBand}>
        <div className={styles.ctaInner}>
          <h2 className={styles.ctaTitle}>Ready to run your<br />photography business?</h2>
          <p className={styles.ctaDesc}>Join thousands of photographers managing bookings, clients, and money — all in one place. Start free today.</p>
          <div className={styles.ctaActions}>
            <Link href={WEB_REGISTER} className={styles.btnPrimary}>Get Started Free →</Link>
            <Link href={WEB_LOGIN} className={styles.btnSecondary}>
              {LANDING_ONLY ? 'Download the App' : 'Open Web App'}
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className={styles.footer}>
        <div className={styles.footerLogo}>Clicker<span>Pro</span></div>
        <div className={styles.footerCopy}>© {new Date().getFullYear()} ClickerPro. All rights reserved.</div>
        <div className={styles.footerLinks}>
          <a href="#">Privacy</a>
          <a href="#">Terms</a>
          <a href="#">Support</a>
          <a href="#">Contact</a>
        </div>
      </footer>
    </>
  );
}
