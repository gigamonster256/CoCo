// mdx-components.jsx — register CoCo syntax highlighting in Nextra
import { useTheme } from 'nextra-theme-docs'

export function useMDXComponents(components) {
  return {
    pre: ({ children, ...props }) => {
      // Find the language from code block metadata
      const childProps = children?.props
      const lang = childProps?.className?.replace('language-', '') || ''

      if (lang === 'coco') {
        // Use our custom mapping
        return (
          <pre
            data-language="coco"
            className="nextra-code-block"
            {...props}
          >
            {children}
          </pre>
        )
      }

      return <pre {...props}>{children}</pre>
    },
    ...components,
  }
}
