{ lib, ... }:
let
  inherit (lib) mkOption types;
  bind =
    default:
    mkOption {
      inherit default;
      type = types.str;
    };
in
{
  options.desktop.keybindings = {
    launcher = bind "Mod+Space";

    monitor = {
      focusMonitorLeft = bind "Mod+N";
      focusMonitorRight = bind "Mod+Period";
      focusMonitorDown = bind "Mod+M";
      focusMonitorUp = bind "Mod+Comma";
      moveToMonitorLeft = bind "Mod2+N";
      moveToMonitorRight = bind "Mod2+Period";
      moveToMonitorDown = bind "Mod2+M";
      moveToMonitorUp = bind "Mod2+Comma";
    };

    navigation = {
      focusColumnLeft = bind "Mod+H";
      focusColumnRight = bind "Mod+L";
      focusWindowUp = bind "Mod+K";
      focusWindowDown = bind "Mod+J";
      moveColumnLeft = bind "Mod2+H";
      moveColumnRight = bind "Mod2+L";
      moveWindowUp = bind "Mod2+K";
      moveWindowDown = bind "Mod2+J";
      focusWorkspaceUp = bind "Mod+I";
      focusWorkspaceDown = bind "Mod+U";
      moveToWorkspaceUp = bind "Mod2+I";
      moveToWorkspaceDown = bind "Mod2+U";
      focusFirstColumn = bind "Mod+Home";
      focusLastColumn = bind "Mod+End";
      moveColumnFirst = bind "Mod2+Home";
      moveColumnLast = bind "Mod2+End";
      consumeFromLeft = bind "Mod+BracketLeft";
      consumeFromRight = bind "Mod+BracketRight";
      expelToLeft = bind "Mod2+BracketLeft";
      expelToRight = bind "Mod2+BracketRight";
      # prefixes generate <prefix>+1..9 binds
      focusWorkspacePrefix = bind "Mod";
      moveToWorkspacePrefix = bind "Mod2";
    };

    layout = {
      resizeWidthDecrease = bind "Mod+Minus";
      resizeWidthIncrease = bind "Mod+Equal";
      resizeHeightDecrease = bind "Mod2+Minus";
      resizeHeightIncrease = bind "Mod2+Equal";
      cyclePresetWidth = bind "Mod+R";
      cyclePresetHeight = bind "Mod2+R";
      maximize = bind "Mod+F";
      fullscreen = bind "Mod2+F";
      expand = bind "Mod+X";
      center = bind "Mod+C";
      toggleFloating = bind "Mod+V";
      switchFloatingFocus = bind "Mod2+V";
    };
  };
}
