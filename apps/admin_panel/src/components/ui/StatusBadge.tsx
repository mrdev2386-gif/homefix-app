interface StatusBadgeProps {
  status: string;
  variant?: 'success' | 'warning' | 'error' | 'info' | 'default' | 'purple';
}

const variantClasses = {
  success: 'badge-success',
  warning: 'badge-warning',
  error: 'badge-error',
  info: 'badge-info',
  default: 'badge-default',
  purple: 'badge-purple',
};

export default function StatusBadge({ status, variant = 'default' }: StatusBadgeProps) {
  return (
    <span className={`badge ${variantClasses[variant]}`}>
      {status}
    </span>
  );
}
