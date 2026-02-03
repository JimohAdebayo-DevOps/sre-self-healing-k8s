from django import forms
import re
from django.core.exceptions import ValidationError

class ServiceForm(forms.Form):
    service_name = forms.CharField(
        label="Service Name", 
        max_length=50,
        help_text="Lowercase letters and hyphens only (e.g., my-payment-service)"
    )

    def clean_service_name(self):
        name = self.cleaned_data['service_name']
        # Enforce Kubernetes naming conventions (DNS-1123)
        if not re.match(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$', name):
            raise ValidationError("Invalid name. Use only lowercase letters, numbers, and hyphens.")
        return name

