import * as React from "react"
import { cn } from "@/lib/utils"
import { Loader2 } from "lucide-react"
// import { Slot } from "@radix-ui/react-slot" // Probably not installed
// So I will just support default button props

const buttonVariants = {
    default: "bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/10 active:scale-[0.98]",
    destructive: "bg-rose-600 text-white hover:bg-rose-500 shadow-lg shadow-rose-600/10 active:scale-[0.98]",
    outline: "border border-slate-800 bg-slate-900/50 text-slate-300 hover:bg-slate-800 hover:text-white active:scale-[0.98]",
    secondary: "bg-slate-800 text-slate-200 hover:bg-slate-700 active:scale-[0.98]",
    ghost: "text-slate-400 hover:bg-slate-800 hover:text-white active:scale-[0.95]",
    link: "text-indigo-400 underline-offset-4 hover:underline",
}


const buttonSizes = {
    default: "h-10 px-4 py-2",
    sm: "h-9 rounded-md px-3",
    lg: "h-11 rounded-md px-8",
    icon: "h-10 w-10",
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
                    "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
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
