import { createI18n } from 'vue-i18n'
import zh from './zh.json'
import en from './en.json'

const savedLang = localStorage.getItem('sn-lang') || 'zh'

const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: savedLang,
  fallbackLocale: 'zh',
  messages: { zh, en },
})

export function setLanguage(lang) {
  i18n.global.locale.value = lang
  localStorage.setItem('sn-lang', lang)
  document.documentElement.lang = lang
}

export function getLanguage() {
  return i18n.global.locale.value
}

export default i18n
