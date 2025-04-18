{{/*
Define common labels for storage resources
*/}}
{{- define "storage-templates.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Define the PV name
*/}}
{{- define "storage-templates.pvName" -}}
{{- if .Values.storage.persistence.pvName -}}
{{- .Values.storage.persistence.pvName -}}
{{- else -}}
{{- printf "%s-pv" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Define the PVC name
*/}}
{{- define "storage-templates.pvcName" -}}
{{- if .Values.storage.persistence.pvcName -}}
{{- .Values.storage.persistence.pvcName -}}
{{- else -}}
{{- printf "%s-pvc" .Release.Name -}}
{{- end -}}
{{- end -}}
