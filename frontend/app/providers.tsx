"use client";

import { ReactNode } from "react";
import { Toaster } from "react-hot-toast";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <>
      {children}
      <Toaster
        position="top-right"
        toastOptions={{
          style: {
            background: "#0a1726",
            color: "#f7efe6",
            border: "1px solid rgba(255,255,255,0.08)",
          },
        }}
      />
    </>
  );
}