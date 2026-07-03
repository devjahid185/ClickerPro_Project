// Clicker Pro — Generative Mountain Scene (vanilla Three.js port)
//
// Renders a solid, undulating Perlin-noise mountain landscape behind the
// hero section. Brand-tinted orange (the reference used sky-blue #7dd3fc).
//
// Performance notes (this file previously made the landing page feel slow):
//   • three.module.js is now self-hosted (three.module.min.js, same folder)
//     instead of fetched from a CDN — no extra DNS/TLS round-trip and no
//     dependency on a third party being up before the animation can start.
//   • Mesh resolution dropped 128×128 → 48×48 segments (~7x fewer vertices
//     for the shader to displace and light every frame) — visually near
//     identical at hero-banner size, much cheaper per frame.
//   • Render loop is capped to ~30fps via a timestamp gate instead of
//     running the shader at full display refresh rate (60/90/120Hz) for a
//     background element nobody is staring straight at.
//   • An IntersectionObserver pauses the animation entirely once the hero
//     scrolls out of view, and resumes it on scroll-back — no wasted GPU
//     work for a canvas nobody can see.
import * as THREE from './three.module.min.js';

export function initMountainScene(mountEl, opts = {}) {
  if (!mountEl) return () => {};

  // Brand orange (#FF6B00). Reference used #7dd3fc (sky blue).
  const brandColor = opts.color || '#FF6B00';

  const scene = new THREE.Scene();

  const camera = new THREE.PerspectiveCamera(
    75,
    mountEl.clientWidth / mountEl.clientHeight,
    0.1,
    100
  );
  camera.position.set(0, 1.5, 3);
  camera.rotation.x = -0.3;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(mountEl.clientWidth, mountEl.clientHeight);
  // Cap pixel ratio at 1.5 (not 2) — a background decoration doesn't need
  // full Retina density, and this alone roughly halves fragment-shader cost
  // on high-DPI phones/laptops.
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
  mountEl.appendChild(renderer.domElement);

  // 48×48 segments (was 128×128) — ~7x fewer vertices for the noise
  // displacement + lighting to run on every frame, visually near-identical
  // at the size this renders on screen.
  const geometry = new THREE.PlaneGeometry(12, 8, 48, 48);

  const material = new THREE.ShaderMaterial({
    side: THREE.DoubleSide,
    wireframe: false,
    transparent: true,
    uniforms: {
      time: { value: 0 },
      pointLightPosition: { value: new THREE.Vector3(0, 0, 5) },
      color: { value: new THREE.Color(brandColor) },
    },
    vertexShader: `
      uniform float time;
      varying vec3 vNormal;
      varying vec3 vPosition;

      vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
      vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
      vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
      vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
      float snoise(vec3 v) {
          const vec2 C = vec2(1.0/6.0, 1.0/3.0);
          const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
          vec3 i = floor(v + dot(v, C.yyy));
          vec3 x0 = v - i + dot(i, C.xxx);
          vec3 g = step(x0.yzx, x0.xyz);
          vec3 l = 1.0 - g;
          vec3 i1 = min(g.xyz, l.zxy);
          vec3 i2 = max(g.xyz, l.zxy);
          vec3 x1 = x0 - i1 + C.xxx;
          vec3 x2 = x0 - i2 + C.yyy;
          vec3 x3 = x0 - D.yyy;
          i = mod289(i);
          vec4 p = permute(permute(permute(
                    i.z + vec4(0.0, i1.z, i2.z, 1.0))
                  + i.y + vec4(0.0, i1.y, i2.y, 1.0))
                  + i.x + vec4(0.0, i1.x, i2.x, 1.0));
          float n_ = 0.142857142857;
          vec3 ns = n_ * D.wyz - D.xzx;
          vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
          vec4 x_ = floor(j * ns.z);
          vec4 y_ = floor(j - 7.0 * x_);
          vec4 x = x_ * ns.x + ns.yyyy;
          vec4 y = y_ * ns.x + ns.yyyy;
          vec4 h = 1.0 - abs(x) - abs(y);
          vec4 b0 = vec4(x.xy, y.xy);
          vec4 b1 = vec4(x.zw, y.zw);
          vec4 s0 = floor(b0) * 2.0 + 1.0;
          vec4 s1 = floor(b1) * 2.0 + 1.0;
          vec4 sh = -step(h, vec4(0.0));
          vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
          vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
          vec3 p0 = vec3(a0.xy, h.x);
          vec3 p1 = vec3(a0.zw, h.y);
          vec3 p2 = vec3(a1.xy, h.z);
          vec3 p3 = vec3(a1.zw, h.w);
          vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
          p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
          vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
          m = m * m;
          return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
      }

      void main() {
          vNormal = normal;
          vPosition = position;
          float noiseFreq = 0.8;
          float noiseAmp = 0.6;
          float displacement = snoise(vec3(position.x * noiseFreq, position.y * noiseFreq - time * 0.2, 0.0)) * noiseAmp;
          displacement += snoise(vec3(position.x * noiseFreq * 2.0, position.y * noiseFreq * 2.0 - time * 0.2, 0.0)) * (noiseAmp * 0.5);
          vec3 newPosition = position + normal * displacement;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
      }
    `,
    fragmentShader: `
      uniform vec3 color;
      uniform vec3 pointLightPosition;
      varying vec3 vNormal;
      varying vec3 vPosition;

      void main() {
          vec3 normal = normalize(vNormal);
          vec3 lightDir = normalize(pointLightPosition - vPosition);
          float diffuse = max(dot(normal, lightDir), 0.0);
          float fresnel = 1.0 - dot(normal, vec3(0.0, 0.0, 1.0));
          fresnel = pow(fresnel, 2.0);
          vec3 finalColor = color * diffuse + color * fresnel * 0.5;
          gl_FragColor = vec4(finalColor, 1.0);
      }
    `,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.rotation.x = -Math.PI / 2;
  scene.add(mesh);

  const pointLight = new THREE.PointLight(0xffffff, 1, 100);
  pointLight.position.set(0, 0, 5);
  scene.add(pointLight);

  // Render loop capped to ~30fps — this is a background decoration, not
  // something that benefits from matching a 90/120Hz display refresh rate.
  const frameInterval = 1000 / 30;
  let lastFrameTime = 0;
  let frameId;
  let paused = false;

  const animate = (t) => {
    frameId = requestAnimationFrame(animate);
    if (paused) return;
    if (t - lastFrameTime < frameInterval) return;
    lastFrameTime = t;
    material.uniforms.time.value = t * 0.0003;
    renderer.render(scene, camera);
  };
  frameId = requestAnimationFrame(animate);

  // Stop rendering entirely once the hero scrolls off-screen (e.g. user has
  // scrolled down to Features/Pricing) — resumes automatically on scroll-back.
  let observer;
  if ('IntersectionObserver' in window) {
    observer = new IntersectionObserver(
      (entries) => {
        paused = !entries[0]?.isIntersecting;
      },
      { threshold: 0 }
    );
    observer.observe(mountEl);
  }

  const handleResize = () => {
    camera.aspect = mountEl.clientWidth / mountEl.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(mountEl.clientWidth, mountEl.clientHeight);
  };

  const handleMouseMove = (e) => {
    const y = -(e.clientY / window.innerHeight) * 2 + 1;
    const x = (e.clientX / window.innerWidth) * 2 - 1;
    const pos = new THREE.Vector3(x * 5, 2, 2 - y * 2);
    pointLight.position.copy(pos);
    material.uniforms.pointLightPosition.value = pos;
  };

  window.addEventListener('resize', handleResize);
  window.addEventListener('mousemove', handleMouseMove);

  // Teardown
  return () => {
    cancelAnimationFrame(frameId);
    observer?.disconnect();
    window.removeEventListener('resize', handleResize);
    window.removeEventListener('mousemove', handleMouseMove);
    if (mountEl.contains(renderer.domElement)) mountEl.removeChild(renderer.domElement);
    geometry.dispose();
    material.dispose();
    renderer.dispose();
  };
}

// Auto-init on the element with id="mountain-scene".
window.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('mountain-scene');
  if (el) {
    try {
      initMountainScene(el);
    } catch (err) {
      // WebGL unavailable — leave the gradient fallback in place.
      console.warn('Mountain scene disabled:', err);
    }
  }
});
