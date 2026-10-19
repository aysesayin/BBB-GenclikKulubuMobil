"""assets/mock/*.json sözleşmelerinden OpenAPI 3.1 taslağı üretir → docs/openapi.yaml.

Kullanım:  python tool/gen_openapi.py
Dosya adı kuralı MockInterceptor ile aynıdır: segmentler '.', '_' = {id}, son ek '.post/.put/.delete' = metod.
Örnek yanıtlar mock dosyalarının kendisidir; şemalar backend ekibince detaylandırılmalıdır.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOCK = ROOT / 'assets' / 'mock'
OUT = ROOT / 'docs' / 'openapi.yaml'
METHODS = {'post', 'put', 'delete', 'patch'}


def parse(name: str):
    parts = name[:-5].split('.')  # .json
    method = 'get'
    if parts[-1] in METHODS:
        method = parts.pop()
    segs = ['{id}' if p == '_' else p for p in parts]
    # aynı yolda birden çok {id} → {id}, {id2}
    seen, out = 0, []
    for s in segs:
        if s == '{id}':
            seen += 1
            out.append('{id}' if seen == 1 else f'{{id{seen}}}')
        else:
            out.append(s)
    return method, '/' + '/'.join(out)


def main():
    paths: dict[str, dict[str, dict]] = {}
    for f in sorted(MOCK.glob('*.json')):
        method, path = parse(f.name)
        body = json.loads(f.read_text(encoding='utf-8'))
        status = str(body.pop('_status', 200))
        op = paths.setdefault(path, {}).setdefault(method, {
            'summary': f'{method.upper()} {path}',
            'parameters': [{'name': p.strip('{}'), 'in': 'path', 'required': True, 'schema': {'type': 'string'}}
                           for p in path.split('/') if p.startswith('{')],
            'responses': {},
        })
        key = f.stem
        resp = op['responses'].setdefault(status, {
            'description': 'Standart zarf' if status.startswith('2') else 'Hata',
            'content': {'application/json': {'schema': {'$ref': '#/components/schemas/Envelope'}, 'examples': {}}},
        })
        resp['content']['application/json']['examples'][key] = {'value': body}
    doc = {
        'openapi': '3.1.0',
        'info': {
            'title': 'Bursa Büyükşehir Gençlik Kulübü API (taslak)',
            'version': '0.1.0',
            'description': 'Mobil uygulamanın mock sözleşmelerinden otomatik üretildi (tool/gen_openapi.py). '
                           'Tüm yanıtlar standart zarf içindedir. Puan / kota / yaş kuralları sunucu tarafındadır.',
        },
        'servers': [{'url': 'https://dev-api.ORNEK.bursa.bel.tr/api/v1'}],
        'components': {
            'securitySchemes': {'bearer': {'type': 'http', 'scheme': 'bearer'}},
            'schemas': {'Envelope': {
                'type': 'object',
                'required': ['success'],
                'properties': {
                    'success': {'type': 'boolean'},
                    'data': {},
                    'message': {'type': 'string'},
                    'errors': {'type': 'array', 'items': {'type': 'object', 'properties': {
                        'field': {'type': 'string'}, 'message': {'type': 'string'}}}},
                    'meta': {'type': 'object', 'properties': {
                        'page': {'type': 'integer'}, 'pageSize': {'type': 'integer'}, 'total': {'type': 'integer'}}},
                },
            }},
        },
        'security': [{'bearer': []}],
        'paths': dict(sorted(paths.items())),
    }
    # JSON, YAML 1.2'nin alt kümesidir → geçerli YAML; okunabilirlik için girintili yazılır.
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text('# Otomatik üretildi: python tool/gen_openapi.py — elle düzenlemeyin.\n'
                   + json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'{len(paths)} yol -> {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
