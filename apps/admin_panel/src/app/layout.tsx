import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
    title: 'HomeFix Admin Portal',
    description: 'Service Marketplace Administration',
    icons: {
        icon: '/favicon.svg',
        shortcut: '/favicon.svg',
        apple: '/favicon.svg',
    },
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="en">
            <body style={{ fontFamily: 'Inter, system-ui, sans-serif' }}>
                {children}
            </body>
        </html>
    )
}
