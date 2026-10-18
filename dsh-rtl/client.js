/**
 * dsh-rtl — النصف الخاص بالمتصفح.
 * يجعل المستند RTL ويضيف طبقة CSS تصحيحية صغيرة (جزر LTR للأكواد).
 * كل الأثر مسجَّل داخل apply عبر ctx.effect، فإلغاء تحميل البلوجن يرجّع كل حاجة.
 */
window.__ModuleLoader__.load({
  id: 'dsh-rtl',
  factory(require) {
    const STYLE_ID = 'dsh-rtl-style';

    const CSS = `
html[dir="rtl"] { direction: rtl; }
html[dir="rtl"] body { direction: rtl; }
/* جزر LTR: الكود والمسارات والطرفية تفضل من الشمال لليمين */
html[dir="rtl"] pre,
html[dir="rtl"] code,
html[dir="rtl"] kbd,
html[dir="rtl"] samp,
html[dir="rtl"] .monaco-editor,
html[dir="rtl"] [data-dsh-ltr] {
  direction: ltr;
  text-align: left;
  unicode-bidi: isolate;
}
html[dir="rtl"] pre code { text-align: left; }
/* مساحات الإدخال تتبع الاتجاه لكن تسمح بالنص المختلط */
html[dir="rtl"] input,
html[dir="rtl"] textarea { unicode-bidi: plaintext; }
`;

    function install() {
      const root = document.documentElement;
      const previousDir = root.getAttribute('dir');
      const previousLang = root.getAttribute('lang');

      root.setAttribute('dir', 'rtl');
      root.setAttribute('lang', 'ar');
      root.setAttribute('data-dsh-rtl', '');

      const existing = document.getElementById(STYLE_ID);
      const style = existing || document.createElement('style');
      style.id = STYLE_ID;
      style.textContent = CSS;
      if (!existing) document.head.appendChild(style);

      return () => {
        if (!existing) style.remove();
        if (previousDir === null) root.removeAttribute('dir');
        else root.setAttribute('dir', previousDir);
        if (previousLang === null) root.removeAttribute('lang');
        else root.setAttribute('lang', previousLang);
        root.removeAttribute('data-dsh-rtl');
      };
    }

    function apply(ctx) {
      const dispose = ctx.effect(() => install());
      void dispose;
    }

    return { inject: [], apply };
  },
});
