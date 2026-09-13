/* Stage-1 control: intentionally empty ARMv7 preload library.
 * This separates ELF DT_NEEDED patching effects from our later Qt hooks.
 */
__attribute__((constructor)) static void z03mods_loaded(void)
{
}
