import * as React from "react"
import { cn } from "@/lib/utils"
import { Loader2 } from "lucide-react"

const buttonVariants = {
    default: "bg-[#6366F1] text-white hover:bg-[#4F46E5] shadow-lg shadow-[#6366F1]/20 active:scale-[0.98] transition-all duration-200",
    destructive: "bg-red-600 text-white hover:bg-red-700 shadow-lg shadow-red-600/20 active:scale-[0.98] transition-all duration-200",
    outline: "border border-[#374151] bg-transparent text-[#E5E7EB] hover:bg-[#1F2937] hover:border-[#6366F1] active:scale-[0.98] transition-all duration-200",
    secondary: "bg-[#1F2937] text-[#E5E7EB] hover:bg-[#374151] active:scale-[0.98] transition-all duration-200",
    ghost: "text-[#9CA3AF] hover:bg-[#1F2937] hover:text-[#E5E7EB] active:scale-[0.95] transition-all duration-200",
    link: "text-[#6366F1] underline-offset-4 hover:underline",
}

const buttonSizes = {
    default: "h-10 px-4 py-2 rounded-lg",
    sm: "h-9 rounded-md px-3",
    lg: "h-11 rounded-lg px-8",
    icon: "h-10 w-10 rounded-lg",
}

export interface ButtonProps
    extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: keyof typeof buttonVariants
    size?: keyof typeof buttonSizes
    asChild?: boolean
    isLoading?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
    ({ className, variant = "default", size = "default", asChild = false, isLoading, children, ...props }, ref) => {
        return (
            <button
                className={cn(
                    "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-[#0B1120] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6366F1] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
                    buttonVariants[variant],
                    buttonSizes[size],
                    className
                )}
                ref={ref}
                disabled={isLoading || props.disabled}
                {...props}
            >
                {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {children}
            </button>
        )
    }
)
Button.displayName = "Button"

export { Button, buttonVariants }
