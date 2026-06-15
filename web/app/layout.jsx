import 'nextra-theme-docs/style.css'

export default function RootLayout({ children }) {
  return (
    <html lang="en" dir="ltr">
      <body>{children}</body>
    </html>
  )
}
