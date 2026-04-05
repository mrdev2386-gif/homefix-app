"use strict";
exports.id = 4896;
exports.ids = [4896];
exports.modules = {

/***/ 1984:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   H: () => (/* binding */ AuthProvider),
/* harmony export */   a: () => (/* binding */ useAuth)
/* harmony export */ });
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6786);
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(8038);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var firebase_auth__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(3129);
/* harmony import */ var next_navigation__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(7114);
/* harmony import */ var next_navigation__WEBPACK_IMPORTED_MODULE_3___default = /*#__PURE__*/__webpack_require__.n(next_navigation__WEBPACK_IMPORTED_MODULE_3__);
/* harmony import */ var _lib_firebase__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(4961);
/* harmony import */ var _lib_auth__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(2033);
/* __next_internal_client_entry_do_not_use__ AuthProvider,useAuth auto */ 





const AuthContext = /*#__PURE__*/ (0,react__WEBPACK_IMPORTED_MODULE_1__.createContext)({
    user: null,
    loading: true,
    isAdmin: false,
    signOut: async ()=>{}
});
const AuthProvider = ({ children })=>{
    const [user, setUser] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(null);
    const [isAdmin, setIsAdmin] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(false);
    const [loading, setLoading] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(true);
    const router = (0,next_navigation__WEBPACK_IMPORTED_MODULE_3__.useRouter)();
    const pathname = (0,next_navigation__WEBPACK_IMPORTED_MODULE_3__.usePathname)();
    // 1. Initial Auth Check (Runs ONCE on mount)
    (0,react__WEBPACK_IMPORTED_MODULE_1__.useEffect)(()=>{
        const unsubscribe = (0,firebase_auth__WEBPACK_IMPORTED_MODULE_2__/* .onAuthStateChanged */ .Aj)(_lib_firebase__WEBPACK_IMPORTED_MODULE_4__/* .auth */ .I8, async (currentUser)=>{
            if (currentUser) {
                try {
                    // Force refresh token to get latest claims as per request
                    await currentUser.getIdToken(true);
                    const tokenResult = await currentUser.getIdTokenResult();
                    if (tokenResult.claims.admin === true) {
                        setUser(currentUser);
                        setIsAdmin(true);
                    } else {
                        console.error("Non-admin user attempted access");
                        await (0,_lib_auth__WEBPACK_IMPORTED_MODULE_5__/* .signOutUser */ .Mx)();
                        setUser(null);
                        setIsAdmin(false);
                    }
                } catch (error) {
                    console.error("Auth verification error:", error);
                    setUser(null);
                    setIsAdmin(false);
                }
            } else {
                setUser(null);
                setIsAdmin(false);
            }
            setLoading(false); // This acts as authReady
        });
        return ()=>unsubscribe();
    }, []);
    // 2. Route Protection (Runs on path change, but fast)
    (0,react__WEBPACK_IMPORTED_MODULE_1__.useEffect)(()=>{
        if (loading) return;
        const publicPaths = [
            "/",
            "/login"
        ];
        const isPublicPath = publicPaths.includes(pathname);
        if (!user && !isPublicPath) {
            router.push("/login");
        } else if (user && !isAdmin && !isPublicPath) {
            router.push("/login?error=not_admin");
        } else if (user && isAdmin && pathname === "/login") {
            router.push("/admin");
        }
    }, [
        user,
        isAdmin,
        loading,
        pathname,
        router
    ]);
    const handleSignOut = async ()=>{
        try {
            await (0,_lib_auth__WEBPACK_IMPORTED_MODULE_5__/* .signOutUser */ .Mx)();
            setUser(null);
            setIsAdmin(false);
            router.push("/login");
        } catch (error) {
            console.error("Error signing out:", error);
        }
    };
    if (loading) {
        return /*#__PURE__*/ (0,react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxs)("div", {
            className: "h-screen w-full flex flex-col items-center justify-center bg-[#020617] gap-4",
            children: [
                /*#__PURE__*/ (0,react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxs)("div", {
                    className: "relative",
                    children: [
                        /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
                            className: "w-12 h-12 border-4 border-indigo-500/20 rounded-full"
                        }),
                        /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("div", {
                            className: "w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"
                        })
                    ]
                }),
                /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx("p", {
                    className: "text-indigo-400/80 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse",
                    children: "Verifying Credentials"
                })
            ]
        });
    }
    return /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx(AuthContext.Provider, {
        value: {
            user,
            loading,
            isAdmin,
            signOut: handleSignOut
        },
        children: children
    });
};
const useAuth = ()=>(0,react__WEBPACK_IMPORTED_MODULE_1__.useContext)(AuthContext);


/***/ }),

/***/ 2121:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   z: () => (/* binding */ Button)
/* harmony export */ });
/* unused harmony export buttonVariants */
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6786);
/* harmony import */ var react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(8038);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var _lib_utils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(2019);
/* harmony import */ var lucide_react__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(5928);




const buttonVariants = {
    default: "bg-[#6366F1] text-white hover:bg-[#4F46E5] shadow-lg shadow-[#6366F1]/20 active:scale-[0.98] transition-all duration-200",
    destructive: "bg-red-600 text-white hover:bg-red-700 shadow-lg shadow-red-600/20 active:scale-[0.98] transition-all duration-200",
    outline: "border border-[#374151] bg-transparent text-[#E5E7EB] hover:bg-[#1F2937] hover:border-[#6366F1] active:scale-[0.98] transition-all duration-200",
    secondary: "bg-[#1F2937] text-[#E5E7EB] hover:bg-[#374151] active:scale-[0.98] transition-all duration-200",
    ghost: "text-[#9CA3AF] hover:bg-[#1F2937] hover:text-[#E5E7EB] active:scale-[0.95] transition-all duration-200",
    link: "text-[#6366F1] underline-offset-4 hover:underline"
};
const buttonSizes = {
    default: "h-10 px-4 py-2 rounded-lg",
    sm: "h-9 rounded-md px-3",
    lg: "h-11 rounded-lg px-8",
    icon: "h-10 w-10 rounded-lg"
};
const Button = /*#__PURE__*/ react__WEBPACK_IMPORTED_MODULE_1__.forwardRef(({ className, variant = "default", size = "default", asChild = false, isLoading, children, ...props }, ref)=>{
    return /*#__PURE__*/ (0,react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxs)("button", {
        className: (0,_lib_utils__WEBPACK_IMPORTED_MODULE_2__.cn)("inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-[#0B1120] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6366F1] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50", buttonVariants[variant], buttonSizes[size], className),
        ref: ref,
        disabled: isLoading || props.disabled,
        ...props,
        children: [
            isLoading && /*#__PURE__*/ react_jsx_runtime__WEBPACK_IMPORTED_MODULE_0__.jsx(lucide_react__WEBPACK_IMPORTED_MODULE_3__/* ["default"] */ .Z, {
                className: "mr-2 h-4 w-4 animate-spin"
            }),
            children
        ]
    });
});
Button.displayName = "Button";



/***/ }),

/***/ 2033:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   Mx: () => (/* binding */ signOutUser),
/* harmony export */   qj: () => (/* binding */ signInWithGoogle),
/* harmony export */   sr: () => (/* binding */ handleAuthError)
/* harmony export */ });
/* unused harmony exports verifyAdminClaim, getAdminToken */
/* harmony import */ var firebase_auth__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(3129);
/* harmony import */ var _firebase__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(4961);
/* __next_internal_client_entry_do_not_use__ signInWithGoogle,verifyAdminClaim,getAdminToken,signOutUser,handleAuthError auto */ 

/**
 * Sign in with Google using popup
 */ async function signInWithGoogle() {
    const provider = new firebase_auth__WEBPACK_IMPORTED_MODULE_0__/* .GoogleAuthProvider */ .hJ();
    provider.setCustomParameters({
        prompt: "select_account"
    });
    return (0,firebase_auth__WEBPACK_IMPORTED_MODULE_0__/* .signInWithPopup */ .rh)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .auth */ .I8, provider);
}
/**
 * Verify if user has admin claim
 */ async function verifyAdminClaim(user) {
    try {
        const tokenResult = await getAdminToken(user);
        console.log("User Claims:", tokenResult.claims);
        return !!tokenResult.claims.admin;
    } catch (error) {
        console.error("Error verifying admin claim:", error);
        return false;
    }
}
/**
 * Get fresh ID token with claims
 */ async function getAdminToken(user) {
    // Requirement: AFTER login, FORCE refresh ID token
    await user.getIdToken(true);
    const tokenResult = await user.getIdTokenResult();
    return tokenResult;
}
/**
 * Sign out and clear state
 */ async function signOutUser() {
    return (0,firebase_auth__WEBPACK_IMPORTED_MODULE_0__/* .signOut */ .w7)(_firebase__WEBPACK_IMPORTED_MODULE_1__/* .auth */ .I8);
}
/**
 * Handle Firebase authentication errors
 */ function handleAuthError(error) {
    const errorCode = error?.code || "";
    switch(errorCode){
        case "auth/popup-blocked":
            return "Popup blocked. Please enable popups and try again.";
        case "auth/popup-closed-by-user":
            return ""; // Silent - user intentionally cancelled
        case "auth/network-request-failed":
            return "Network error. Please check your connection.";
        case "auth/too-many-requests":
            return "Too many attempts. Please try again later.";
        case "auth/unauthorized-domain":
            return "This domain is not authorized. Please contact support.";
        case "auth/user-not-found":
        case "auth/wrong-password":
            return "Invalid email or password. Please try again.";
        default:
            return error?.message || "Authentication failed. Please try again.";
    }
}


/***/ }),

/***/ 4961:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   I8: () => (/* binding */ auth),
/* harmony export */   db: () => (/* binding */ db),
/* harmony export */   wk: () => (/* binding */ functions)
/* harmony export */ });
/* unused harmony export app */
/* harmony import */ var firebase_app__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(2856);
/* harmony import */ var firebase_auth__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3129);
/* harmony import */ var firebase_firestore__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(1522);
/* harmony import */ var firebase_functions__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(3997);
/* __next_internal_client_entry_do_not_use__ app,auth,db,functions auto */ 


const firebaseConfig = {
    apiKey: "AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI",
    authDomain: "homefix-aa42d.firebaseapp.com",
    projectId: "homefix-aa42d",
    storageBucket: "homefix-aa42d.firebasestorage.app",
    messagingSenderId: "663243229047",
    appId: "1:663243229047:web:generic_web_id"
};

let app, auth, db, functions;
if (false) {}



/***/ }),

/***/ 2019:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   cn: () => (/* binding */ cn)
/* harmony export */ });
/* harmony import */ var clsx__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(566);
/* harmony import */ var tailwind_merge__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8126);


function cn(...inputs) {
    return (0,tailwind_merge__WEBPACK_IMPORTED_MODULE_0__/* .twMerge */ .m6)((0,clsx__WEBPACK_IMPORTED_MODULE_1__/* .clsx */ .W)(inputs));
}


/***/ })

};
;