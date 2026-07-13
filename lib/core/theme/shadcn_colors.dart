import 'package:flutter/material.dart';

/// shadcn/ui inspired design tokens — dark IDE aesthetic.
/// No gradients. Professional console feel.
abstract final class ShadcnColors {
  // Background layers (zinc-based dark)
  static const background = Color(0xFF09090B); // zinc-950
  static const foreground = Color(0xFFFAFAFA); // zinc-50
  static const card = Color(0xFF09090B);
  static const cardForeground = Color(0xFFFAFAFA);
  static const popover = Color(0xFF09090B);
  static const popoverForeground = Color(0xFFFAFAFA);

  // Primary (cloud blue accent)
  static const primary = Color(0xFF3B82F6); // blue-500
  static const primaryForeground = Color(0xFFFAFAFA);

  // Secondary / muted
  static const secondary = Color(0xFF27272A); // zinc-800
  static const secondaryForeground = Color(0xFFFAFAFA);
  static const muted = Color(0xFF27272A);
  static const mutedForeground = Color(0xFFA1A1AA); // zinc-400
  static const accent = Color(0xFF27272A);
  static const accentForeground = Color(0xFFFAFAFA);

  // Semantic
  static const destructive = Color(0xFFEF4444);
  static const destructiveForeground = Color(0xFFFAFAFA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF38BDF8);

  // Borders / inputs
  static const border = Color(0xFF27272A);
  static const input = Color(0xFF27272A);
  static const ring = Color(0xFF3B82F6);

  // Sidebar (IDE rail)
  static const sidebar = Color(0xFF0C0C0E);
  static const sidebarForeground = Color(0xFFFAFAFA);
  static const sidebarBorder = Color(0xFF1C1C1F);
  static const sidebarAccent = Color(0xFF18181B);
  static const sidebarPrimary = Color(0xFF3B82F6);

  // Panel chrome
  static const panel = Color(0xFF111113);
  static const panelHeader = Color(0xFF141416);
  static const tabActive = Color(0xFF18181B);
  static const tabInactive = Color(0xFF0C0C0E);

  // Provider brand accents (subtle, not flashy)
  static const aws = Color(0xFFFF9900);
  static const azure = Color(0xFF0078D4);
  static const gcp = Color(0xFF4285F4);
  static const linux = Color(0xFFFCC624);
  static const docker = Color(0xFF2496ED);
  static const k8s = Color(0xFF326CE5);
  static const terraform = Color(0xFF7B42BC);

  // Chart series
  static const chart1 = Color(0xFF3B82F6);
  static const chart2 = Color(0xFF22C55E);
  static const chart3 = Color(0xFFF59E0B);
  static const chart4 = Color(0xFFA855F7);
  static const chart5 = Color(0xFFEF4444);

  // Terminal
  static const terminalBg = Color(0xFF0A0A0A);
  static const terminalFg = Color(0xFFE4E4E7);
  static const terminalGreen = Color(0xFF4ADE80);
  static const terminalCyan = Color(0xFF22D3EE);
  static const terminalYellow = Color(0xFFFACC15);
  static const terminalRed = Color(0xFFF87171);
}
