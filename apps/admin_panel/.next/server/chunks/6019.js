"use strict";
exports.id = 6019;
exports.ids = [6019];
exports.modules = {

/***/ 6019:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {


// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  QH: () => (/* reexport */ ConfirmDialog/* default */.Z),
  wQ: () => (/* reexport */ DataTable),
  u_: () => (/* reexport */ Modal/* default */.Z),
  mr: () => (/* reexport */ PageHeader/* default */.Z),
  Rm: () => (/* reexport */ StatCard),
  OE: () => (/* reexport */ StatusBadge),
  iA: () => (/* reexport */ Table)
});

// UNUSED EXPORTS: Badge, Button, Card, CardSkeleton, EmptyState, ErrorState, FilterBar, Input, LoadingState, Skeleton, TableSkeleton

// EXTERNAL MODULE: external "next/dist/compiled/react/jsx-runtime"
var jsx_runtime_ = __webpack_require__(6786);
;// CONCATENATED MODULE: ./src/components/ui/StatusBadge.tsx

const variantClasses = {
    success: "badge-success",
    warning: "badge-warning",
    error: "badge-error",
    info: "badge-info",
    default: "badge-default",
    purple: "badge-purple"
};
function StatusBadge({ status, variant = "default" }) {
    return /*#__PURE__*/ jsx_runtime_.jsx("span", {
        className: `badge ${variantClasses[variant]}`,
        children: status
    });
}

// EXTERNAL MODULE: external "next/dist/compiled/react"
var react_ = __webpack_require__(8038);
;// CONCATENATED MODULE: ./src/components/ui/FilterBar.tsx



function FilterBar({ searchPlaceholder = "Search...", searchValue = "", onSearchChange, filters = [], filterValues = {}, onFilterChange, onClearFilters }) {
    const hasActiveFilters = searchValue || Object.values(filterValues).some((v)=>v);
    return /*#__PURE__*/ _jsx("div", {
        className: "admin-card p-4",
        children: /*#__PURE__*/ _jsxs("div", {
            className: "flex flex-col md:flex-row gap-4",
            children: [
                onSearchChange && /*#__PURE__*/ _jsxs("div", {
                    className: "flex-1 relative",
                    children: [
                        /*#__PURE__*/ _jsx(Search, {
                            className: "absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6B7280]"
                        }),
                        /*#__PURE__*/ _jsx("input", {
                            type: "text",
                            placeholder: searchPlaceholder,
                            value: searchValue,
                            onChange: (e)=>onSearchChange(e.target.value),
                            className: "input-field w-full pl-10 pr-4"
                        })
                    ]
                }),
                filters.map((filter)=>/*#__PURE__*/ _jsx("div", {
                        className: "min-w-[200px]",
                        children: /*#__PURE__*/ _jsxs("select", {
                            value: filterValues[filter.key] || "",
                            onChange: (e)=>onFilterChange?.(filter.key, e.target.value),
                            className: "input-field w-full px-4 py-2",
                            children: [
                                /*#__PURE__*/ _jsx("option", {
                                    value: "",
                                    children: filter.label
                                }),
                                filter.options.map((option)=>/*#__PURE__*/ _jsx("option", {
                                        value: option.value,
                                        children: option.label
                                    }, option.value))
                            ]
                        })
                    }, filter.key)),
                hasActiveFilters && onClearFilters && /*#__PURE__*/ _jsxs("button", {
                    onClick: onClearFilters,
                    className: "flex items-center gap-2 px-4 py-2 bg-[#1F2937] hover:bg-[#374151] text-[#E5E7EB] rounded-lg transition-colors whitespace-nowrap",
                    children: [
                        /*#__PURE__*/ _jsx(X, {
                            className: "w-4 h-4"
                        }),
                        "Clear"
                    ]
                })
            ]
        })
    });
}

// EXTERNAL MODULE: ./src/components/ui/ConfirmDialog.tsx
var ConfirmDialog = __webpack_require__(1057);
// EXTERNAL MODULE: ./src/components/ui/EmptyState.tsx
var EmptyState = __webpack_require__(5224);
// EXTERNAL MODULE: ./src/components/ui/ErrorState.tsx
var ErrorState = __webpack_require__(4892);
// EXTERNAL MODULE: ./src/components/ui/LoadingState.tsx
var LoadingState = __webpack_require__(2760);
// EXTERNAL MODULE: ./src/components/ui/Button.tsx
var Button = __webpack_require__(2121);
// EXTERNAL MODULE: ./src/components/ui/Card.tsx
var Card = __webpack_require__(9057);
// EXTERNAL MODULE: ./src/components/ui/Input.tsx
var Input = __webpack_require__(7048);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/arrow-up-down.mjs
var arrow_up_down = __webpack_require__(3279);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/chevron-left.mjs
var chevron_left = __webpack_require__(251);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/chevron-right.mjs
var chevron_right = __webpack_require__(4834);
;// CONCATENATED MODULE: ./src/components/ui/Table.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 


function Table({ columns, data, loading, pagination, onSort, sortConfig, emptyMessage = "No data found.", className }) {
    if (loading) {
        return /*#__PURE__*/ jsx_runtime_.jsx("div", {
            className: `w-full bg-[#111827] rounded-xl border border-[#1F2937] p-8 space-y-4 ${className || ""}`,
            children: [
                1,
                2,
                3,
                4,
                5
            ].map((i)=>/*#__PURE__*/ jsx_runtime_.jsx("div", {
                    className: "h-12 bg-[#1F2937] rounded-lg animate-pulse"
                }, i))
        });
    }
    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
        className: `bg-[#111827] rounded-xl border border-[#1F2937] shadow-lg overflow-hidden ${className || ""}`,
        children: [
            /*#__PURE__*/ jsx_runtime_.jsx("div", {
                className: "overflow-x-auto",
                children: /*#__PURE__*/ (0,jsx_runtime_.jsxs)("table", {
                    className: "w-full text-left border-collapse",
                    children: [
                        /*#__PURE__*/ jsx_runtime_.jsx("thead", {
                            children: /*#__PURE__*/ jsx_runtime_.jsx("tr", {
                                className: "bg-[#0F172A] border-b border-[#1F2937]",
                                children: columns.map((col)=>/*#__PURE__*/ jsx_runtime_.jsx("th", {
                                        className: `
                                        px-4 py-3 text-xs font-semibold text-[#9CA3AF] uppercase tracking-wider whitespace-nowrap
                                        ${col.sortable ? "cursor-pointer hover:bg-[#1F2937] transition-colors group" : ""}
                                    `,
                                        style: {
                                            textAlign: col.align || "left"
                                        },
                                        onClick: ()=>col.sortable && onSort && onSort(col.key),
                                        children: /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                                            className: `flex items-center gap-2 ${col.align === "right" ? "justify-end" : col.align === "center" ? "justify-center" : "justify-start"}`,
                                            children: [
                                                col.label,
                                                col.sortable && /*#__PURE__*/ jsx_runtime_.jsx(arrow_up_down/* default */.Z, {
                                                    size: 14,
                                                    className: "text-[#6B7280] group-hover:text-[#6366F1]"
                                                })
                                            ]
                                        })
                                    }, col.key))
                            })
                        }),
                        /*#__PURE__*/ jsx_runtime_.jsx("tbody", {
                            className: "divide-y divide-[#1F2937]",
                            children: data.length > 0 ? data.map((item, index)=>/*#__PURE__*/ jsx_runtime_.jsx("tr", {
                                    className: "hover:bg-[#1F2937]/50 transition-colors",
                                    children: columns.map((col)=>/*#__PURE__*/ jsx_runtime_.jsx("td", {
                                            className: "px-4 py-3 align-middle",
                                            style: {
                                                textAlign: col.align || "left"
                                            },
                                            children: col.render ? col.render(item, index) : /*#__PURE__*/ jsx_runtime_.jsx("span", {
                                                className: "text-sm text-[#E5E7EB]",
                                                children: item[col.key]
                                            })
                                        }, `${item.id}-${col.key}`))
                                }, item.id || index)) : /*#__PURE__*/ jsx_runtime_.jsx("tr", {
                                children: /*#__PURE__*/ jsx_runtime_.jsx("td", {
                                    colSpan: columns.length,
                                    className: "px-4 py-16 text-center",
                                    children: /*#__PURE__*/ jsx_runtime_.jsx("p", {
                                        className: "text-[#6B7280] text-sm",
                                        children: emptyMessage
                                    })
                                })
                            })
                        })
                    ]
                })
            }),
            pagination && pagination.totalPages > 1 && /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                className: "border-t border-[#1F2937] px-6 py-4 flex items-center justify-between bg-[#0F172A]",
                children: [
                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("p", {
                        className: "text-sm text-[#9CA3AF]",
                        children: [
                            "Page ",
                            pagination.currentPage,
                            " of ",
                            pagination.totalPages
                        ]
                    }),
                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                        className: "flex items-center gap-2",
                        children: [
                            /*#__PURE__*/ jsx_runtime_.jsx("button", {
                                onClick: ()=>pagination.onPageChange(Math.max(1, pagination.currentPage - 1)),
                                disabled: pagination.currentPage === 1,
                                className: "p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]",
                                children: /*#__PURE__*/ jsx_runtime_.jsx(chevron_left/* default */.Z, {
                                    size: 18
                                })
                            }),
                            /*#__PURE__*/ jsx_runtime_.jsx("button", {
                                onClick: ()=>pagination.onPageChange(Math.min(pagination.totalPages, pagination.currentPage + 1)),
                                disabled: pagination.currentPage === pagination.totalPages,
                                className: "p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]",
                                children: /*#__PURE__*/ jsx_runtime_.jsx(chevron_right/* default */.Z, {
                                    size: 18
                                })
                            })
                        ]
                    })
                ]
            })
        ]
    });
}

// EXTERNAL MODULE: ./src/components/ui/Badge.tsx
var Badge = __webpack_require__(9545);
;// CONCATENATED MODULE: ./src/components/ui/StatCard.tsx

const colorClasses = {
    blue: "bg-blue-500/20 text-blue-400 border-blue-500/30",
    green: "bg-green-500/20 text-green-400 border-green-500/30",
    orange: "bg-yellow-500/20 text-yellow-400 border-yellow-500/30",
    red: "bg-red-500/20 text-red-400 border-red-500/30",
    purple: "bg-[#6366F1]/20 text-[#6366F1] border-[#6366F1]/30",
    gray: "bg-gray-500/20 text-gray-400 border-gray-500/30"
};
function StatCard({ title, value, icon: Icon, trend, color = "purple", loading }) {
    return /*#__PURE__*/ jsx_runtime_.jsx("div", {
        className: "admin-card p-6 hover:shadow-[0_0_20px_rgba(99,102,241,0.15)] hover:border-[#6366F1]/30 transition-all duration-300",
        children: /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
            className: "flex items-center justify-between",
            children: [
                /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                    className: "flex-1",
                    children: [
                        /*#__PURE__*/ jsx_runtime_.jsx("p", {
                            className: "text-sm text-[#9CA3AF] mb-1",
                            children: title
                        }),
                        loading ? /*#__PURE__*/ jsx_runtime_.jsx("div", {
                            className: "h-8 w-24 bg-[#1F2937] animate-pulse rounded"
                        }) : /*#__PURE__*/ jsx_runtime_.jsx("h3", {
                            className: "text-2xl font-bold text-[#E5E7EB]",
                            children: value
                        }),
                        trend && !loading && /*#__PURE__*/ (0,jsx_runtime_.jsxs)("p", {
                            className: `text-sm mt-2 ${trend.isPositive ? "text-green-400" : "text-red-400"}`,
                            children: [
                                trend.isPositive ? "↑" : "↓",
                                " ",
                                trend.value
                            ]
                        })
                    ]
                }),
                /*#__PURE__*/ jsx_runtime_.jsx("div", {
                    className: `w-12 h-12 rounded-lg flex items-center justify-center border flex-shrink-0 ${colorClasses[color]}`,
                    children: /*#__PURE__*/ jsx_runtime_.jsx(Icon, {
                        size: 24
                    })
                })
            ]
        })
    });
}

// EXTERNAL MODULE: ./src/components/ui/PageHeader.tsx
var PageHeader = __webpack_require__(5570);
;// CONCATENATED MODULE: ./src/components/ui/DataTable.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 

function DataTable({ columns, data, loading, pagination, onSort, sortConfig, emptyMessage, actions, title }) {
    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
        className: "space-y-4",
        children: [
            (title || actions) && /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                className: "flex items-center justify-between",
                children: [
                    title && /*#__PURE__*/ jsx_runtime_.jsx("h3", {
                        className: "text-lg font-semibold text-[#E5E7EB]",
                        children: title
                    }),
                    actions && /*#__PURE__*/ jsx_runtime_.jsx("div", {
                        className: "flex items-center gap-2",
                        children: actions
                    })
                ]
            }),
            /*#__PURE__*/ jsx_runtime_.jsx(Table, {
                columns: columns,
                data: data,
                loading: loading,
                pagination: pagination,
                onSort: onSort,
                sortConfig: sortConfig,
                emptyMessage: emptyMessage
            })
        ]
    });
}

// EXTERNAL MODULE: ./src/components/ui/Modal.tsx
var Modal = __webpack_require__(7535);
;// CONCATENATED MODULE: ./src/components/ui/index.ts
// Shared UI Components for Admin Finance & Settings Module

















/***/ })

};
;