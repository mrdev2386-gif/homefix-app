import * as React from "react"
import { cn } from "@/lib/utils"

const badgeVariants = {
    default: "bg-primary text-primary-foreground hover:bg-primary/80 border-transparent",
    secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80 border-transparent",
    destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/80 border-transparent",
    outline: "text-foreground border-border", // Outline style
    success: "bg-green-100 text-green-800 border-green-200",
    warning: "bg-yellow-100 text-yellow-800 border-yellow-200",
    info: "bg-blue-100 text-blue-800 border-blue-200",
    slate: "bg-slate-100 text-slate-800 border-slate-200"
} as const

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
    variant?: keyof typeof badgeVariants
}

function Badge({ className, variant = "default", ...props }: BadgeProps) {
    return (
        <div className={cn(
            "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
            badgeVariants[variant],
            className
        )} {...props} />
    )
}

export { Badge, badgeVariants }
