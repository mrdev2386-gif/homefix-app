exports.id = 1779;
exports.ids = [1779];
exports.modules = {

/***/ 1710:
/***/ ((__unused_webpack_module, __unused_webpack_exports, __webpack_require__) => {

Promise.resolve(/* import() eager */).then(__webpack_require__.bind(__webpack_require__, 7281))

/***/ }),

/***/ 1212:
/***/ ((__unused_webpack_module, __unused_webpack_exports, __webpack_require__) => {

Promise.resolve(/* import() eager */).then(__webpack_require__.bind(__webpack_require__, 4598))

/***/ }),

/***/ 7281:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "default": () => (/* binding */ AdminRootLayout)
});

// EXTERNAL MODULE: external "next/dist/compiled/react/jsx-runtime"
var jsx_runtime_ = __webpack_require__(6786);
// EXTERNAL MODULE: external "next/dist/compiled/react"
var react_ = __webpack_require__(8038);
// EXTERNAL MODULE: ./node_modules/next/navigation.js
var navigation = __webpack_require__(7114);
// EXTERNAL MODULE: ./node_modules/next/link.js
var next_link = __webpack_require__(1440);
var link_default = /*#__PURE__*/__webpack_require__.n(next_link);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/layout-dashboard.mjs
var layout_dashboard = __webpack_require__(7566);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/calendar.mjs
var calendar = __webpack_require__(8205);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/clipboard-list.mjs
var clipboard_list = __webpack_require__(5010);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/file-text.mjs
var file_text = __webpack_require__(6053);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/users.mjs
var users = __webpack_require__(9452);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/shield.mjs
var shield = __webpack_require__(65);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/settings.mjs
var settings = __webpack_require__(3835);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/user-check.mjs
var user_check = __webpack_require__(4476);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/briefcase.mjs
var briefcase = __webpack_require__(6753);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/star.mjs
var star = __webpack_require__(8891);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/alert-triangle.mjs
var alert_triangle = __webpack_require__(9803);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/wrench.mjs
var wrench = __webpack_require__(8163);
;// CONCATENATED MODULE: ./src/components/Sidebar.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 



const menuItems = [
    {
        name: "Dashboard",
        href: "/admin",
        icon: layout_dashboard/* default */.Z
    },
    {
        name: "Bookings",
        href: "/bookings",
        icon: calendar/* default */.Z
    },
    {
        name: "Booking Approvals",
        href: "/booking-approvals",
        icon: clipboard_list/* default */.Z
    },
    {
        name: "Custom Requests",
        href: "/custom-requests",
        icon: file_text/* default */.Z
    },
    {
        name: "Technicians",
        href: "/technicians",
        icon: users/* default */.Z
    },
    {
        name: "Technician Approvals",
        href: "/technician-approvals",
        icon: shield/* default */.Z
    },
    {
        name: "Service Approvals",
        href: "/service-approvals",
        icon: settings/* default */.Z
    },
    {
        name: "Applications",
        href: "/applications",
        icon: user_check/* default */.Z
    },
    {
        name: "Customers",
        href: "/customers",
        icon: users/* default */.Z
    },
    {
        name: "Services",
        href: "/services",
        icon: briefcase/* default */.Z
    },
    {
        name: "Reviews",
        href: "/reviews",
        icon: star/* default */.Z
    },
    {
        name: "Disputes",
        href: "/disputes",
        icon: alert_triangle/* default */.Z
    }
];
function Sidebar({ collapsed }) {
    const pathname = (0,navigation.usePathname)();
    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)("aside", {
        className: `fixed left-0 top-0 h-screen bg-[#0F172A] border-r border-[#1F2937] transition-all duration-300 z-20 ${collapsed ? "w-20" : "w-64"}`,
        children: [
            /*#__PURE__*/ jsx_runtime_.jsx("div", {
                className: "flex items-center justify-center h-16 px-4 border-b border-[#1F2937]",
                children: collapsed ? /*#__PURE__*/ jsx_runtime_.jsx((link_default()), {
                    href: "/admin",
                    className: "w-10 h-10 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-lg flex items-center justify-center hover:shadow-[0_0_15px_rgba(99,102,241,0.5)] transition-all duration-300 cursor-pointer",
                    children: /*#__PURE__*/ jsx_runtime_.jsx(wrench/* default */.Z, {
                        size: 20,
                        className: "text-white"
                    })
                }) : /*#__PURE__*/ (0,jsx_runtime_.jsxs)((link_default()), {
                    href: "/admin",
                    className: "hover:opacity-80 transition-opacity cursor-pointer flex items-center gap-2",
                    children: [
                        /*#__PURE__*/ jsx_runtime_.jsx("div", {
                            className: "w-8 h-8 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-lg flex items-center justify-center",
                            children: /*#__PURE__*/ jsx_runtime_.jsx(wrench/* default */.Z, {
                                size: 16,
                                className: "text-white"
                            })
                        }),
                        /*#__PURE__*/ jsx_runtime_.jsx("h1", {
                            className: "font-bold text-xl text-gradient",
                            children: "HomeFix"
                        })
                    ]
                })
            }),
            /*#__PURE__*/ jsx_runtime_.jsx("nav", {
                className: "p-3 space-y-1 overflow-y-auto h-[calc(100vh-4rem)] scrollbar-thin scrollbar-thumb-[#1F2937] scrollbar-track-transparent",
                children: menuItems.map((item)=>{
                    const Icon = item.icon;
                    const isActive = pathname === item.href || item.href !== "/admin" && pathname.startsWith(item.href);
                    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)((link_default()), {
                        href: item.href,
                        className: `sidebar-item ${isActive ? "sidebar-item-active" : "sidebar-item-inactive"}`,
                        title: collapsed ? item.name : undefined,
                        children: [
                            /*#__PURE__*/ jsx_runtime_.jsx(Icon, {
                                size: 20,
                                className: isActive ? "text-[#6366F1]" : "text-[#9CA3AF]"
                            }),
                            !collapsed && /*#__PURE__*/ jsx_runtime_.jsx("span", {
                                className: "text-sm font-medium",
                                children: item.name
                            })
                        ]
                    }, item.href);
                })
            })
        ]
    });
}

// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/menu.mjs
var menu = __webpack_require__(819);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/bell.mjs
var bell = __webpack_require__(642);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/user.mjs
var icons_user = __webpack_require__(8401);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/loader-2.mjs
var loader_2 = __webpack_require__(5928);
// EXTERNAL MODULE: ./node_modules/lucide-react/dist/esm/icons/log-out.mjs
var log_out = __webpack_require__(7854);
// EXTERNAL MODULE: ./src/components/AuthProvider.tsx
var AuthProvider = __webpack_require__(1984);
;// CONCATENATED MODULE: ./src/components/Topbar.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 




function Topbar({ onToggleSidebar, pageTitle }) {
    const [showProfileMenu, setShowProfileMenu] = (0,react_.useState)(false);
    const [isLoggingOut, setIsLoggingOut] = (0,react_.useState)(false);
    const router = (0,navigation.useRouter)();
    const { signOut, user } = (0,AuthProvider/* useAuth */.a)();
    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)("header", {
        className: "h-16 bg-[#0F172A] border-b border-[#1F2937] flex items-center justify-between px-6 sticky top-0 z-10",
        children: [
            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                className: "flex items-center gap-4",
                children: [
                    /*#__PURE__*/ jsx_runtime_.jsx("button", {
                        onClick: onToggleSidebar,
                        className: "p-2 hover:bg-[#1F2937] rounded-lg transition-colors",
                        "aria-label": "Toggle sidebar",
                        children: /*#__PURE__*/ jsx_runtime_.jsx(menu/* default */.Z, {
                            size: 20,
                            className: "text-[#E5E7EB]"
                        })
                    }),
                    /*#__PURE__*/ jsx_runtime_.jsx("h2", {
                        className: "text-xl font-semibold text-[#E5E7EB]",
                        children: pageTitle
                    })
                ]
            }),
            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                className: "flex items-center gap-4",
                children: [
                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("button", {
                        className: "relative p-2 hover:bg-[#1F2937] rounded-lg transition-colors",
                        "aria-label": "Notifications",
                        children: [
                            /*#__PURE__*/ jsx_runtime_.jsx(bell/* default */.Z, {
                                size: 20,
                                className: "text-[#9CA3AF]"
                            }),
                            /*#__PURE__*/ jsx_runtime_.jsx("span", {
                                className: "absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"
                            })
                        ]
                    }),
                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                        className: "relative pl-4 border-l border-[#1F2937]",
                        children: [
                            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("button", {
                                onClick: ()=>setShowProfileMenu(!showProfileMenu),
                                className: "flex items-center gap-3 hover:bg-[#1F2937] rounded-lg p-2 transition-colors",
                                children: [
                                    /*#__PURE__*/ jsx_runtime_.jsx("div", {
                                        className: "w-8 h-8 bg-gradient-to-br from-[#6366F1] to-[#7C3AED] rounded-full flex items-center justify-center",
                                        children: /*#__PURE__*/ jsx_runtime_.jsx(icons_user/* default */.Z, {
                                            size: 16,
                                            className: "text-white"
                                        })
                                    }),
                                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                                        className: "hidden md:block text-left",
                                        children: [
                                            /*#__PURE__*/ jsx_runtime_.jsx("p", {
                                                className: "text-sm font-medium text-[#E5E7EB]",
                                                children: "Admin"
                                            }),
                                            /*#__PURE__*/ jsx_runtime_.jsx("p", {
                                                className: "text-xs text-[#9CA3AF]",
                                                children: "admin@homefix.com"
                                            })
                                        ]
                                    })
                                ]
                            }),
                            showProfileMenu && /*#__PURE__*/ (0,jsx_runtime_.jsxs)(jsx_runtime_.Fragment, {
                                children: [
                                    /*#__PURE__*/ jsx_runtime_.jsx("div", {
                                        className: "fixed inset-0 z-10",
                                        onClick: ()=>setShowProfileMenu(false)
                                    }),
                                    /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                                        className: "absolute right-0 mt-2 w-48 bg-[#111827] border border-[#1F2937] rounded-lg shadow-xl py-1 z-20",
                                        children: [
                                            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("button", {
                                                onClick: ()=>{
                                                    setShowProfileMenu(false);
                                                    router.push("/settings");
                                                },
                                                className: "w-full flex items-center gap-3 px-4 py-2 text-sm text-[#9CA3AF] hover:bg-[#1F2937] hover:text-[#E5E7EB] transition-colors",
                                                children: [
                                                    /*#__PURE__*/ jsx_runtime_.jsx(settings/* default */.Z, {
                                                        size: 16
                                                    }),
                                                    "Settings"
                                                ]
                                            }),
                                            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("button", {
                                                onClick: async ()=>{
                                                    setShowProfileMenu(false);
                                                    setIsLoggingOut(true);
                                                    try {
                                                        await signOut();
                                                    } catch (error) {
                                                        console.error("Logout error:", error);
                                                        setIsLoggingOut(false);
                                                    }
                                                },
                                                disabled: isLoggingOut,
                                                className: "w-full flex items-center gap-3 px-4 py-2 text-sm text-red-400 hover:bg-[#1F2937] transition-colors disabled:opacity-50 disabled:cursor-not-allowed",
                                                children: [
                                                    isLoggingOut ? /*#__PURE__*/ jsx_runtime_.jsx(loader_2/* default */.Z, {
                                                        size: 16,
                                                        className: "animate-spin"
                                                    }) : /*#__PURE__*/ jsx_runtime_.jsx(log_out/* default */.Z, {
                                                        size: 16
                                                    }),
                                                    isLoggingOut ? "Logging out..." : "Logout"
                                                ]
                                            })
                                        ]
                                    })
                                ]
                            })
                        ]
                    })
                ]
            })
        ]
    });
}

;// CONCATENATED MODULE: ./src/components/AdminLayout.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 




const pageTitles = {
    "/admin": "Dashboard",
    "/bookings": "Bookings",
    "/custom-requests": "Custom Requests",
    "/applications": "Technician Applications",
    "/technicians": "Technicians",
    "/customers": "Customers",
    "/services": "Services",
    "/reviews": "Reviews",
    "/disputes": "Disputes"
};
function AdminLayout({ children }) {
    const [sidebarCollapsed, setSidebarCollapsed] = (0,react_.useState)(false);
    const pathname = (0,navigation.usePathname)();
    const pageTitle = pageTitles[pathname] || "Admin Panel";
    return /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
        className: "min-h-screen bg-[#0B1120]",
        children: [
            /*#__PURE__*/ jsx_runtime_.jsx(Sidebar, {
                collapsed: sidebarCollapsed
            }),
            /*#__PURE__*/ (0,jsx_runtime_.jsxs)("div", {
                className: `transition-all duration-300 ${sidebarCollapsed ? "ml-20" : "ml-64"}`,
                children: [
                    /*#__PURE__*/ jsx_runtime_.jsx(Topbar, {
                        onToggleSidebar: ()=>setSidebarCollapsed(!sidebarCollapsed),
                        pageTitle: pageTitle
                    }),
                    /*#__PURE__*/ jsx_runtime_.jsx("main", {
                        className: "p-6",
                        children: children
                    })
                ]
            })
        ]
    });
}

;// CONCATENATED MODULE: ./src/app/(admin)/layout.tsx
/* __next_internal_client_entry_do_not_use__ default auto */ 


function AdminRootLayout({ children }) {
    return /*#__PURE__*/ jsx_runtime_.jsx(AuthProvider/* AuthProvider */.H, {
        children: /*#__PURE__*/ jsx_runtime_.jsx(AdminLayout, {
            children: children
        })
    });
}


/***/ }),

/***/ 4598:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (/* binding */ Loading)
/* harmony export */ });
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6786);
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__);
/* __next_internal_client_entry_do_not_use__ default auto */ 
function Loading() {
    return /*#__PURE__*/ (0,react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxs)("div", {
        className: "min-h-screen bg-slate-50 flex flex-col items-center justify-center gap-4",
        children: [
            /*#__PURE__*/ (0,react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxs)("div", {
                className: "relative",
                children: [
                    /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
                        className: "w-16 h-16 border-4 border-indigo-100 rounded-full animate-spin"
                    }),
                    /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
                        className: "w-16 h-16 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin absolute top-0 left-0"
                    })
                ]
            }),
            /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("p", {
                className: "text-slate-400 font-black uppercase tracking-[0.2em] text-xs animate-pulse",
                children: "Accessing Node"
            })
        ]
    });
}


/***/ }),

/***/ 9545:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   C: () => (/* binding */ Badge)
/* harmony export */ });
/* unused harmony export badgeVariants */
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6786);
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(8038);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var _lib_utils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(2019);



const badgeVariants = {
    default: "bg-primary text-primary-foreground hover:bg-primary/80 border-transparent",
    secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80 border-transparent",
    destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/80 border-transparent",
    outline: "text-foreground border-border",
    success: "bg-green-100 text-green-800 border-green-200",
    warning: "bg-yellow-100 text-yellow-800 border-yellow-200",
    info: "bg-blue-100 text-blue-800 border-blue-200",
    slate: "bg-slate-100 text-slate-800 border-slate-200"
};
function Badge({ className, variant = "default", ...props }) {
    return /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2", badgeVariants[variant], className),
        ...props
    });
}



/***/ }),

/***/ 9057:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   Ol: () => (/* binding */ CardHeader),
/* harmony export */   Zb: () => (/* binding */ Card),
/* harmony export */   aY: () => (/* binding */ CardContent),
/* harmony export */   ll: () => (/* binding */ CardTitle)
/* harmony export */ });
/* unused harmony exports CardFooter, CardDescription */
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6786);
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(8038);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var _lib_utils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(2019);



const Card = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("rounded-xl border bg-[#111827] border-[#1F2937] shadow-lg text-[#E5E7EB]", className),
        ...props
    }));
Card.displayName = "Card";
const CardHeader = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("flex flex-col space-y-1.5 p-6", className),
        ...props
    }));
CardHeader.displayName = "CardHeader";
const CardTitle = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("h3", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("text-xl font-semibold leading-none tracking-tight text-[#E5E7EB]", className),
        ...props
    }));
CardTitle.displayName = "CardTitle";
const CardDescription = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("p", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("text-sm text-[#9CA3AF]", className),
        ...props
    }));
CardDescription.displayName = "CardDescription";
const CardContent = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("p-6 pt-0", className),
        ...props
    }));
CardContent.displayName = "CardContent";
const CardFooter = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, ...props }, ref)=>/*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
        ref: ref,
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("flex items-center p-6 pt-0", className),
        ...props
    }));
CardFooter.displayName = "CardFooter";



/***/ }),

/***/ 8610:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   $$typeof: () => (/* binding */ $$typeof),
/* harmony export */   __esModule: () => (/* binding */ __esModule),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var next_dist_build_webpack_loaders_next_flight_loader_module_proxy__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(1363);

const proxy = (0,next_dist_build_webpack_loaders_next_flight_loader_module_proxy__WEBPACK_IMPORTED_MODULE_0__.createProxy)(String.raw`c:\Users\yash\projects\homefix\apps\admin_panel\src\app\(admin)\layout.tsx`)

// Accessing the __esModule property and exporting $$typeof are required here.
// The __esModule getter forces the proxy target to create the default export
// and the $$typeof value is for rendering logic to determine if the module
// is a client boundary.
const { __esModule, $$typeof } = proxy;
const __default__ = proxy.default;


/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (__default__);

/***/ }),

/***/ 4548:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   $$typeof: () => (/* binding */ $$typeof),
/* harmony export */   __esModule: () => (/* binding */ __esModule),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var next_dist_build_webpack_loaders_next_flight_loader_module_proxy__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(1363);

const proxy = (0,next_dist_build_webpack_loaders_next_flight_loader_module_proxy__WEBPACK_IMPORTED_MODULE_0__.createProxy)(String.raw`c:\Users\yash\projects\homefix\apps\admin_panel\src\app\(admin)\loading.tsx`)

// Accessing the __esModule property and exporting $$typeof are required here.
// The __esModule getter forces the proxy target to create the default export
// and the $$typeof value is for rendering logic to determine if the module
// is a client boundary.
const { __esModule, $$typeof } = proxy;
const __default__ = proxy.default;


/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (__default__);

/***/ })

};
;