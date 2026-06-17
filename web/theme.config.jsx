export default {
  logo: <strong>CoCo</strong>,
  project: {
    link: "https://github.com/gigamonster256/coco-compiler",
  },
  docsRepositoryBase: "https://github.com/gigamonster256/coco-compiler/tree/main/website",
  footer: {
    content: <span>CoCo Language Reference — recovered from compiler implementation.</span>,
  },
  useNextSeoProps() {
    return {
      titleTemplate: "%s – CoCo Language",
    };
  },
  sidebar: {
    defaultMenuCollapseLevel: 2,
  },
  toc: {
    backToTop: true,
  },
  feedback: { content: null },
  editLink: { content: null },
};
