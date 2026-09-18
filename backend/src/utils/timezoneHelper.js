/**
 * Timezone utility helpers using the native ECMAScript Internationalization API.
 * This guarantees consistent timezone calculations across server environments without external dependencies.
 */

/**
 * Returns the current date and time formatted in the target timezone.
 * @param {string} timezone - IANA timezone identifier (e.g., 'Asia/Kolkata', 'America/New_York')
 * @param {Date} [referenceDate=new Date()] - Reference timestamp
 * @returns {{ dateString: string, timeString: string, hour: number, minute: number }}
 */
export function getLocalVendorDateTime(timezone, referenceDate = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });

  const parts = formatter.formatToParts(referenceDate);
  const map = {};
  for (const p of parts) {
    map[p.type] = p.value;
  }

  const dateString = `${map.year}-${map.month}-${map.day}`;
  let hour = parseInt(map.hour, 10);
  if (hour === 24) {
    hour = 0;
  }
  const minute = parseInt(map.minute, 10);
  const hourStr = String(hour).padStart(2, '0');
  const minuteStr = String(minute).padStart(2, '0');
  const timeString = `${hourStr}:${minuteStr}`;

  return { dateString, timeString, hour, minute };
}

/**
 * Formats a Date object or ISO date string to a YYYY-MM-DD string in the target timezone.
 * @param {Date|string} date
 * @param {string} timezone
 * @returns {string} YYYY-MM-DD
 */
export function formatDateInTimezone(date, timezone) {
  const d = date instanceof Date ? date : new Date(date);
  return getLocalVendorDateTime(timezone, d).dateString;
}

/**
 * Compares two 24-hour time strings in "HH:mm" format.
 * Returns negative if timeA < timeB, 0 if equal, positive if timeA > timeB.
 * @param {string} timeA - "HH:mm"
 * @param {string} timeB - "HH:mm"
 * @returns {number}
 */
export function compareTimes(timeA, timeB) {
  const [hA, mA] = timeA.split(':').map((v) => parseInt(v, 10));
  const [hB, mB] = timeB.split(':').map((v) => parseInt(v, 10));

  if (hA !== hB) {
    return hA - hB;
  }
  return mA - mB;
}

/**
 * Checks whether targetDateString matches today, is in the future, or is in the past
 * relative to the vendor's operational timezone.
 * @param {string} targetDateString - YYYY-MM-DD
 * @param {string} timezone - IANA timezone
 * @param {Date} [referenceDate=new Date()]
 * @returns {'today'|'future'|'past'}
 */
export function getDateRelationToVendorToday(targetDateString, timezone, referenceDate = new Date()) {
  const { dateString: vendorToday } = getLocalVendorDateTime(timezone, referenceDate);

  if (targetDateString === vendorToday) {
    return 'today';
  }
  return targetDateString > vendorToday ? 'future' : 'past';
}

/**
 * Normalizes a date to UTC midnight for consistent daily schedule querying.
 * @param {string|Date} input
 * @returns {Date}
 */
export function normalizeDateToUtcMidnight(input) {
  const date = typeof input === 'string' ? new Date(input) : input;
  const year = date.getUTCFullYear();
  const month = date.getUTCMonth();
  const day = date.getUTCDate();
  return new Date(Date.UTC(year, month, day, 0, 0, 0, 0));
}
