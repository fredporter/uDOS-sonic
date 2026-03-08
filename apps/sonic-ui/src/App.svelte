<script>
  import { onMount } from "svelte";

  let ready = false;
  let loading = true;
  let loadError = "";
  let summary = null;
  let devices = [];

  async function load() {
    loading = true;
    loadError = "";
    try {
      const [summaryResponse, devicesResponse] = await Promise.all([
        fetch("/api/sonic/gui/summary"),
        fetch("/api/sonic/devices?limit=8")
      ]);

      if (!summaryResponse.ok || !devicesResponse.ok) {
        throw new Error("Sonic API is unavailable.");
      }

      summary = await summaryResponse.json();
      const devicePayload = await devicesResponse.json();
      devices = devicePayload.items ?? [];
    } catch (error) {
      loadError = error instanceof Error ? error.message : "Unable to load Sonic data.";
    } finally {
      loading = false;
    }
  }

  onMount(() => {
    ready = true;
    load();
  });
</script>

<main class={`min-h-screen px-6 pb-20 pt-10 transition-all duration-700 ${ready ? "opacity-100" : "opacity-0"}`}>
  <section class="mx-auto flex max-w-6xl flex-col gap-8">
    <header class="flex flex-col gap-4">
      <div class="flex items-center gap-3 text-xs uppercase tracking-[0.3em] text-neon-blue">
        <span class="h-[1px] w-10 bg-neon-blue"></span>
        uDOS-sonic
      </div>
      <div class="flex flex-col gap-3">
        <h1 class="text-4xl font-semibold text-white md:text-5xl">
          {summary?.headline ?? "Standalone deployment system for uDOS and profile-aware hardware installs."}
        </h1>
        <p class="max-w-2xl text-sm text-slate-300 md:text-base">
          API-first Sonic control surface with a live browser GUI, manifest validation, and an
          optional MCP facade for operators and agents.
        </p>
      </div>
      <div class="flex flex-wrap gap-3">
        <button class="glass px-4 py-2 text-xs uppercase tracking-[0.2em] text-neon-green shadow-glow" on:click={load}>
          Refresh summary
        </button>
        <button class="glass px-4 py-2 text-xs uppercase tracking-[0.2em] text-slate-200">
          API + MCP facade
        </button>
      </div>
    </header>

    {#if loadError}
      <section class="glass rounded-xl border border-rose-400/30 p-5 text-sm text-rose-200">
        {loadError} Start `python3 apps/sonic-cli/cli.py serve-api` to feed the browser UI.
      </section>
    {/if}

    <section class="grid gap-6 md:grid-cols-3">
      {#each summary?.boot_modes ?? [] as mode}
        <div class="glass scanline flex flex-col gap-3 rounded-xl p-5">
          <div class="flex items-center justify-between">
            <span class="text-lg font-semibold text-white">{mode.name}</span>
            <span class={`text-[10px] uppercase tracking-[0.2em] ${mode.status === "default" ? "text-neon-green" : "text-slate-400"}`}>
              {mode.status === "default" ? "default" : "ready"}
            </span>
          </div>
          <p class="text-xs uppercase tracking-[0.2em] text-slate-400">{mode.role}</p>
          <p class="text-sm text-slate-300">{mode.detail}</p>
          <button class="mt-2 w-fit rounded-full border border-neon-blue/30 px-3 py-1 text-xs uppercase tracking-[0.2em] text-neon-blue">
            Boot config
          </button>
        </div>
      {/each}
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
      <div class="glass rounded-xl p-6">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold text-white">Partition layout v2</h2>
          <span class="text-xs uppercase tracking-[0.2em] text-slate-400">
            {summary?.manifest?.ok ? "manifest valid" : "manifest pending"}
          </span>
        </div>
        <div class="mt-5 space-y-3">
          {#each summary?.partitions ?? [] as part}
            <div class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-white/5 bg-ink-900/60 px-4 py-3">
              <div>
                <p class="text-sm font-semibold text-white">{part.label}</p>
                <p class="text-xs text-slate-400">{part.role ?? part.name}</p>
              </div>
              <div class="text-right text-xs text-slate-300">
                <p>{part.remainder ? "remainder" : `${part.size_gb} GB`}</p>
                <p class="text-neon-blue">{part.fs.toUpperCase()}</p>
              </div>
            </div>
          {/each}
        </div>
      </div>

      <div class="glass rounded-xl p-6">
        <h2 class="text-xl font-semibold text-white">Build pulse</h2>
        <ul class="mt-4 space-y-3 text-sm text-slate-300">
          {#each summary?.build_pulse ?? [] as item}
            <li>{item}</li>
          {/each}
        </ul>
        <div class="mt-6 rounded-lg border border-white/5 bg-ink-900/70 p-4 text-xs text-slate-400">
          {#if loading}
            Loading live Sonic status...
          {:else}
            Catalog records: {summary?.summary?.device_records ?? 0}. Platform:
            {summary?.summary?.platform ?? "unknown"}.
          {/if}
        </div>
      </div>
    </section>

    <section class="glass rounded-xl p-6">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-semibold text-white">Device database snapshot</h2>
          <p class="text-sm text-slate-400">Merged catalog view from the Sonic DB service.</p>
        </div>
        <button class="rounded-full border border-white/10 px-4 py-2 text-xs uppercase tracking-[0.2em] text-slate-200" on:click={load}>
          Sync catalog
        </button>
      </div>
      <div class="mt-4 overflow-hidden rounded-lg border border-white/5">
        <table class="w-full text-left text-xs text-slate-300">
          <thead class="bg-ink-900/80 text-[10px] uppercase tracking-[0.2em] text-slate-500">
            <tr>
              <th class="px-4 py-3">Device</th>
              <th class="px-4 py-3">Vendor</th>
              <th class="px-4 py-3">Boot</th>
              <th class="px-4 py-3">Windows</th>
              <th class="px-4 py-3">Media</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/5">
            {#each devices as device}
              <tr class="bg-ink-900/40">
                <td class="px-4 py-3 font-semibold text-white">{device.id}</td>
                <td class="px-4 py-3">{device.vendor}</td>
                <td class="px-4 py-3">{device.uefi_native}</td>
                <td class="px-4 py-3 text-neon-blue">{device.windows}</td>
                <td class="px-4 py-3 text-neon-green">{device.media}</td>
              </tr>
            {/each}
            {#if !devices.length && !loading}
              <tr class="bg-ink-900/40">
                <td class="px-4 py-3 text-slate-400" colspan="5">No device rows available.</td>
              </tr>
            {/if}
          </tbody>
        </table>
      </div>
    </section>
  </section>
</main>
