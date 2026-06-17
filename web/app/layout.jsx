import { Footer, Layout, Navbar } from "nextra-theme-docs";
import { Head } from "nextra/components";
import { getPageMap } from "nextra/page-map";
import "nextra-theme-docs/style.css";

export const metadata = {
  title: {
    template: "%s – CoCo",
    default: "CoCo Language",
  },
  description: "CoCo Language Reference",
};

const navbar = <Navbar logo={<b>CoCo</b>} />;
const footer = <Footer>CoCo Language Reference</Footer>;

export default async function RootLayout({ children }) {
  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <script src="/lib/coco/coco_js.js" defer />
        <Layout
          navbar={navbar}
          pageMap={await getPageMap()}
          docsRepositoryBase="https://github.com/gigamonster256/coco-compiler"
          footer={footer}
        >
          {children}
        </Layout>
      </body>
    </html>
  );
}
