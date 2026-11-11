<script setup lang="ts">
import type { IntakeEntry } from '../../shared/types'
defineProps<{ entries: IntakeEntry[] }>()
const channels: Record<string, string> = { slack: 'Slack', mail: 'Mail', teams: 'Teams', inbox: 'Inbox folder', terminal: 'Terminal', unknown: 'Unknown channel' }
const outcomes: Record<string, string> = {
  direction: 'Direction',
  'slice-candidate': 'Slice candidate',
  'research-ticket': 'Research ticket',
  parked: 'Parked',
  rejected: 'Rejected',
  untriaged: 'Not triaged yet',
}
const outcomeLabel = (e: IntakeEntry) => (e.waitingOnHuman ? 'Needs you' : outcomes[e.outcome])
const flight = (e: IntakeEntry) => (e.provenance.kind === 'in-flight' ? `in flight: ${e.provenance.item}` : null)
</script>

<template>
  <section class="intake" data-test="intake-queue" aria-label="Intake queue">
    <h3>Intake queue</h3>
    <p v-if="!entries.length">No ideas have come in.</p>
    <ul v-else>
      <li v-for="e in entries" :key="e.id" :class="{ waiting: e.waitingOnHuman }" :data-waiting="e.waitingOnHuman || undefined" :data-test="e.waitingOnHuman ? 'intake-waiting' : 'intake-entry'">
        <strong data-test="intake-title">{{ e.title }}</strong>
        <span class="chip" data-test="intake-channel">{{ channels[e.channel] }}</span>
        <span class="chip" data-test="intake-outcome">{{ outcomeLabel(e) }}</span>
        <span v-if="flight(e)" class="chip" data-test="provenance">{{ flight(e) }}</span>
        <p v-if="e.reason" class="reason" data-test="intake-reason">{{ e.reason }}</p>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.intake ul { list-style: none; padding: 0; margin: 0; }
.intake li { border: 1px solid currentColor; border-radius: 6px; padding: 0.5rem 0.8rem; margin: 0.4rem 0; }
.intake li.waiting { border-width: 2px; border-left-width: 6px; font-weight: bold; }
.chip { display: inline-block; font-size: 0.8rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.6rem; margin-left: 0.4rem; }
.reason { margin: 0.2rem 0 0; font-weight: normal; overflow-wrap: anywhere; }
</style>
