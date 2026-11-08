from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("api", "0007_storedfile")]

    operations = [
        migrations.AddField(model_name="user", name="reset_code_hash", field=models.CharField(max_length=64, blank=True, default="")),
        migrations.AddField(model_name="user", name="reset_expires", field=models.DateTimeField(null=True, blank=True)),
        migrations.AddField(model_name="user", name="reset_attempts", field=models.IntegerField(default=0)),
    ]
