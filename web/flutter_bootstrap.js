{{flutter_js}}
{{flutter_build_config}}

// Sayfada #flutter-host varsa uygulama o kutuya gömülür (masaüstünde telefon çerçevesi);
// yoksa tüm sayfayı kaplar. CanvasKit yerel kopyadan yüklenir (--no-web-resources-cdn).
const host = document.querySelector('#flutter-host');
_flutter.loader.load({
  config: host ? { hostElement: host } : {},
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine(host ? { hostElement: host } : {});
    await appRunner.runApp();
    document.body.classList.add('flutter-ready');
  },
});
